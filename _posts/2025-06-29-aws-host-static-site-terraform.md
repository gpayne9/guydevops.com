---
title: "Hosting a Jekyll Site on AWS with Terraform, S3 & CloudFront"
description: "How I set up guydevops.com — a Jekyll blog served from S3 behind CloudFront, provisioned with Terraform. Runs for under $2/month."
date: 2025-06-29
tags: [Jekyll, Terraform, AWS, S3, CloudFront, Route53, DevOps, Infrastructure as Code, ACM, Static Site]
categories: [DevOps, Tutorials, AWS, Infrastructure]
---

<div align="center" style="margin: 2rem 0;">
  <h3 style="color: #666; margin-bottom: 1rem;"><i class="fas fa-tools"></i> Tech Stack</h3>
  <div style="display: flex; justify-content: center; align-items: center; gap: 2rem; flex-wrap: wrap;">
    <div style="text-align: center;">
      <img src="https://jekyllrb.com/img/logo-2x.png" alt="Jekyll" width="80" style="margin-bottom: 0.5rem;"/>
      <br><small><strong>Jekyll</strong></small>
    </div>
    <div style="text-align: center;">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/terraform/terraform-original.svg" alt="Terraform" width="80" style="margin-bottom: 0.5rem;"/>
      <br><small><strong>Terraform</strong></small>
    </div>
    <div style="text-align: center;">
      <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/amazonwebservices/amazonwebservices-original-wordmark.svg" alt="AWS" width="80" style="margin-bottom: 0.5rem;"/>
      <br><small><strong>AWS</strong></small>
    </div>
  </div>
</div>

This is how I set up [guydevops.com](https://guydevops.com) — a Jekyll blog sitting in an S3 bucket, served through CloudFront, with DNS and TLS handled by Route 53 and ACM. Everything is provisioned with Terraform and the whole thing costs under $2/month.

## Why This Setup

| Problem | How this stack handles it |
|---|---|
| Patching, scaling, paying for servers | Jekyll produces static HTML. No servers to manage. |
| Click-ops and config drift | Terraform codifies the infrastructure. Version-controlled and reviewable. |
| Slow loads for visitors far from origin | CloudFront caches at 400+ edge locations. |
| TLS certificate renewals | ACM issues free certs and auto-renews them. |
| Vendor lock-in | It's static files. Move them to Netlify, Vercel, or anywhere else whenever. |

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    User Browser                       │
└──────────────┬───────────────────────────────────────┘
               │ 1. DNS Query (guydevops.com)
               ▼
┌──────────────────────────────────────────────────────┐
│              Route 53 (DNS)                           │
│              Returns CloudFront IP                    │
└──────────────┬───────────────────────────────────────┘
               │ 2. HTTPS Request
               ▼
┌──────────────────────────────────────────────────────┐
│            CloudFront (CDN)                           │
│            400+ Edge Locations                        │
│            TLS via ACM Certificate                    │
└──────────────┬───────────────────────────────────────┘
               │ 3. Origin fetch (cache miss only)
               ▼
┌──────────────────────────────────────────────────────┐
│            S3 Bucket (Static Website)                 │
│            Jekyll _site/ output                       │
└──────────────────────────────────────────────────────┘

Terraform manages all of the above.
State stored in a separate S3 bucket.
```

Everything lives in **us-east-1** because CloudFront requires ACM certificates in that region.

---

## Prerequisites

- Ruby 3.1 or 3.2 — 3.3+ has stdlib changes that break Jekyll 4.x
- AWS account with IAM access
- AWS CLI and Terraform >= 1.2
- A registered domain with a Route 53 hosted zone

---

## 1. Create the Jekyll Site

I use the [Chirpy theme](https://github.com/cotes2020/jekyll-theme-chirpy) as a gem dependency. Get it running locally first:

```bash
git clone https://github.com/<YOU>/<REPO>.git && cd <REPO>
gem install bundler jekyll
bundle install
bundle exec jekyll serve   # verify at http://127.0.0.1:4000
```

Edit `_config.yml` with your site info, write posts in `_posts/`, then build:

```bash
jekyll build   # outputs to _site/
```

Keep `_site` in `.gitignore` — we sync it to S3 separately.

---

## 2. Set Up Remote State

Before writing any Terraform:

1. Create a private S3 bucket (mine is called `guy-terraform-state`)
2. Enable versioning for state history
3. Optionally add a DynamoDB table for state locking

---

## 3. Terraform

Here are the key files. Full source is in [my repo](https://github.com/gpayne9/guydevops.com/tree/master/terraform).

<details>
<summary><strong>main.tf</strong></summary>

<div markdown="1">

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {
    bucket = "guy-terraform-state"
    key    = "terraform"
    region = "us-east-1"
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
```

</div>
</details>

<details>
<summary><strong>s3.tf — Bucket with Referer-based access policy</strong></summary>

<div markdown="1">

```hcl
variable "secret_header" {
  type    = string
  default = "secret-header"   # prevents direct bucket access
}

variable "site_path" {
  type    = string
  default = "~/repos/guydevops.com"
}

resource "aws_s3_bucket" "guydevops-com_s3_bucket" {
  bucket = "guydevops.com"
  tags   = { Name = "guydevops", Environment = "prod" }
}

resource "aws_s3_bucket_website_configuration" "guydevops-com_s3_bucket_website" {
  bucket = aws_s3_bucket.guydevops-com_s3_bucket.id
  index_document { suffix = "index.html" }
}

# Only allow reads when the Referer header matches.
# CloudFront injects this header on every origin request.
resource "aws_s3_bucket_policy" "allow_public_access_to_site" {
  bucket = aws_s3_bucket.guydevops-com_s3_bucket.id
  policy = data.aws_iam_policy_document.allow_public_access_to_site_policy.json
}

data "aws_iam_policy_document" "allow_public_access_to_site_policy" {
  statement {
    principals { type = "*" identifiers = ["*"] }
    actions   = ["s3:GetObject"]
    resources = [
      aws_s3_bucket.guydevops-com_s3_bucket.arn,
      "${aws_s3_bucket.guydevops-com_s3_bucket.arn}/*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:Referer"
      values   = [var.secret_header]
    }
  }
}

# Syncs the built site to S3 on every terraform apply
resource "null_resource" "remove_and_upload_to_s3" {
  triggers    = { always_run = timestamp() }
  provisioner "local-exec" {
    command = "aws s3 sync ${pathexpand(var.site_path)}/_site s3://${aws_s3_bucket.guydevops-com_s3_bucket.id}"
  }
}
```

</div>
</details>

<details>
<summary><strong>acm_cert.tf — TLS certificate with DNS validation</strong></summary>

<div markdown="1">

```hcl
data "aws_route53_zone" "guydevops_zone" { name = "guydevops.com" }

resource "aws_acm_certificate" "guydevops_cert" {
  domain_name       = "guydevops.com"
  validation_method = "DNS"
}

resource "aws_route53_record" "guydevops_cert_record" {
  for_each = {
    for dvo in aws_acm_certificate.guydevops_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.guydevops_zone.zone_id
}

resource "aws_acm_certificate_validation" "guydevops_cert_validation" {
  certificate_arn         = aws_acm_certificate.guydevops_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.guydevops_cert_record : r.fqdn]
}
```

</div>
</details>

### cloudfront.tf

CloudFront uses a custom origin (the S3 website endpoint, not the REST API endpoint) and injects the secret Referer header so the bucket policy allows the request through.

```hcl
resource "aws_cloudfront_distribution" "guydevops_cf_dis" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.guydevops-com_s3_bucket_website.website_endpoint
    origin_id   = "S3Origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    custom_header { name = "Referer" value = var.secret_header }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["guydevops.com"]

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.guydevops_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["RU", "CN", "KP", "IR"]
    }
  }
}

resource "aws_route53_record" "guydevops_record" {
  name    = "guydevops.com"
  type    = "A"
  zone_id = data.aws_route53_zone.guydevops_zone.zone_id
  alias {
    name                   = aws_cloudfront_distribution.guydevops_cf_dis.domain_name
    zone_id                = aws_cloudfront_distribution.guydevops_cf_dis.hosted_zone_id
    evaluate_target_health = false
  }
}
```

---

## 4. Deploy

```bash
jekyll build          # generate _site/
terraform init        # pull providers, configure backend
terraform plan        # review what gets created
terraform apply       # provision everything
```

Takes about 5 minutes. Most of that is CloudFront distribution deployment.

---

## 5. Automate Deployments

Instead of running `terraform apply` every time you publish a post, set up GitHub Actions to build the site and sync to S3 on push. I have a [deploy workflow](https://github.com/gpayne9/guydevops.com/blob/master/.github/workflows/ci.yml) that does this using OIDC for AWS authentication — no static credentials needed.

---

## What It Costs

| Resource | Monthly |
|---|---|
| S3 Storage (1 GB) | $0.02 |
| CloudFront (10 GB transfer) | $0.85 |
| ACM Certificate | Free |
| Route 53 Hosted Zone | $0.50 |
| **Total** | **< $2/month** |

Assumes moderate traffic. Even at higher volumes, static hosting on AWS stays cheap.

---

## Wrapping Up

You end up with a static site on a global CDN with auto-renewing TLS, managed entirely through Terraform. No servers to patch, nothing to scale, and it costs less than a coffee.

Some things worth adding:
- **www subdomain** — add it as a CloudFront alias with a redirect
- **CloudWatch alarms** — get notified on 4xx/5xx spikes
- **WAF** — if you want DDoS protection beyond what CloudFront provides by default

**Troubleshooting notes:**
- CloudFront cache changes can take 5-15 minutes to propagate (or invalidate manually)
- Route 53 DNS changes can take up to 48 hours
- If Jekyll builds fail, check Ruby version — stick with 3.1 or 3.2

---

*Questions? Find me on [GitHub](https://github.com/gpayne9) or [LinkedIn](https://linkedin.com/in/guy-p-devops).*
