---
title: "Host a Lightning‑Fast Jekyll Site on AWS with Terraform, S3 & CloudFront"
description: "Comprehensive, step‑by‑step guide to building and deploying a secure, globally‑distributed Jekyll website using Terraform, Amazon S3, CloudFront, and Route 53 — complete with diagrams and visuals."
date: 2025-06-29
mermaid: true   
tags: [Jekyll, Terraform, AWS, S3, CloudFront, Route53, Static Site, DevOps, Infrastructure as Code, CDN, SSL Certificate, ACM, Web Hosting, Cloud Architecture, Cost Optimization, Performance, Security, Automation, CI/CD, GitHub Actions, Domain Management, DNS, HTTPS, Static Site Generator, Serverless, AWS CLI, Ruby, Markdown, Blog Hosting, Website Deployment]
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

> **Goal:** Serve <https://guydevops.com> from a **zero‑maintenance** static stack that costs pennies a month yet scales to millions of page views.

---

## Why This Architecture?

| Pain Point                                   | How the Stack Solves It                                                       |
| -------------------------------------------- | ----------------------------------------------------------------------------- |
| **Patching, scaling, or paying for servers** | **Jekyll** produces plain HTML; no servers to manage.                         |
| **Repetitive click-ops & drift**             | **Terraform** codifies infrastructure (version-controlled, reviewable).       |
| **Global latency & SEO ranking**             | **CloudFront** caches content at 400+ PoPs → lightning TTFB.                  |
| **TLS certificate renewals**                 | **ACM** issues & auto-renews free certificates.                               |
| **Vendor lock-in**                           | Static assets can be migrated anywhere (Netlify, Vercel, Azure Blob Storage…) |

---

## High‑Level Architecture <i class="fas fa-sitemap"></i>

<div align="center" style="background: rgba(23, 162, 184, 0.1); border: 1px solid rgba(23, 162, 184, 0.3); padding: 1rem; border-radius: 8px; margin: 1rem 0;">
  <strong style="color: #17a2b8;"><i class="fas fa-bullseye"></i> High-Performance Static Site Architecture</strong>
</div>

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           🌐 User Browser                                   │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
                          │ 1. DNS Query (guydevops.com)
                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        📍 Route 53 (DNS)                                   │
│                    Returns CloudFront IP                                   │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
                          │ 2. HTTPS Request
                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      🚀 CloudFront (CDN)                                   │
│                   400+ Global Edge Locations                               │
│                     ├─ 🔒 ACM Certificate                                  │
│                     └─ Cache: HTML, CSS, JS, Images                        │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
                          │ 3. Origin Request (cache miss)
                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       🪣 S3 Static Website                                 │
│                      Static Files: Jekyll Build                            │
│                    index.html, assets/, _site/                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                      🏗️  Terraform Management                              │
│                                                                             │
│  Terraform CLI/CI  ──────────────┐                                         │
│         │                        │                                         │
│         │                        ▼                                         │
│         │                 📦 S3 Remote State                               │
│         │                                                                  │
│         └─── Creates & Manages ───┐                                        │
│                                   │                                        │
│              ┌────────────────────┼────────────────────┐                   │
│              │                    │                    │                   │
│              ▼                    ▼                    ▼                   │
│         Route 53              CloudFront              S3                   │
│                                   │                                        │
│                                   └─── 🔒 ACM Certificate                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Benefits:**
- <i class="fas fa-globe" style="color: #17a2b8;"></i> **Global CDN**: CloudFront serves from 400+ edge locations
- <i class="fas fa-dollar-sign" style="color: #28a745;"></i> **Cost-effective**: ~$2/month for most personal sites
- <i class="fas fa-shield-alt" style="color: #dc3545;"></i> **Secure**: Free SSL certificates with auto-renewal
- <i class="fas fa-chart-line" style="color: #6f42c1;"></i> **Scalable**: Handles traffic spikes automatically
- <i class="fas fa-tools" style="color: #fd7e14;"></i> **Infrastructure as Code**: Everything version-controlled

*All resources are created in **us‑east‑1** to satisfy CloudFront's ACM regional requirement.*

---

## Prerequisites <i class="fas fa-wrench"></i>
- **Ruby 3.1 / 3.2** (recommended) — *3.3+ splits stdlib; Jekyll 4.x still assumes built‑in `csv`.*
- AWS account with basic IAM familiarity
- AWS CLI & Terraform ≥ 1.2 installed
- Git & GitHub
- A registered domain and a Route 53 hosted zone (e.g., `guydevops.com`)

---

## 1  Create the Jekyll Site (Chirpy Theme)
1. **Fork** the [Chirpy starter](https://github.com/cotes2020/jekyll-theme-chirpy) (or clone directly).
2. Install dependencies & preview locally:
   ```bash
   git clone https://github.com/<YOU>/<REPO>.git && cd <REPO>
   rbenv local 3.2.2          # if you downgraded Ruby
   gem install bundler jekyll
   bundle install
   bundle exec jekyll s       # http://127.0.0.1:4000
   ```
3. Edit `_config.yml` (site title, description, social links) and write posts in `_posts/` using Markdown.
4. Generate static HTML:
   ```bash
   jekyll build               # outputs → _site/
   ```

> **Tip:** Commit the `_site` directory to `.gitignore`; we’ll sync it directly to S3 via Terraform or CI.

---

## 2  Prepare AWS for Remote State
1. **Create a private S3 bucket** called `guy-terraform-state`.
2. Enable **versioning** for state history.
3. (Optional) Create a DynamoDB table for state locking.
4. Configure credentials (profile or IAM role) so Terraform can read/write state.

---

## 3  Infrastructure as Code
Here are the key Terraform files. You can grab the complete versions from [my repo](https://github.com/gpayne9/guydevops.com/tree/c83d1761ea1f453e7167c5e36449f4d56a26793c/terraform).

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
<summary><strong>s3.tf — Static‑Site Bucket (existing name preserved)</strong></summary>

<div markdown="1">

```hcl
variable "secret_header" {
  type    = string
  default = "secret-header"   # keep secret this is to prevent direct access to the bucket
}

variable "site_path" {
  type    = string
  default = "~/repos/guydevops.com"
}

resource "aws_s3_bucket" "guydevops-com_s3_bucket" {
  bucket = "guydevops.com"   # DO NOT CHANGE
  tags   = { Name = "guydevops", Environment = "prod" }
}

resource "aws_s3_bucket_website_configuration" "guydevops-com_s3_bucket_website" {
  bucket = aws_s3_bucket.guydevops-com_s3_bucket.id
  index_document { suffix = "index.html" }
}

# Bucket policy allows only CloudFront (Referer header) to read
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

# Quick‑and‑dirty deploy — replace with CI for production!
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
<summary><strong>acm_cert.tf</strong></summary>

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

## 4  Deploy <i class="fas fa-rocket"></i>
```bash
jekyll build          # generate _site/
terraform init        # download providers & configure backend
terraform plan        # review infra changes
terraform apply       # confirm & provision
```
Provisioning takes **≈5 minutes**.

---

## 5  Automate Updates
Add a GitHub Actions workflow that:
1. Checks out your repo.
2. Caches Ruby gems.
3. Runs `jekyll build`.
4. Uploads the `_site` folder to an artifact or directly to S3.
5. Executes `terraform apply -auto-approve`.

---

## Cost Snapshot <i class="fas fa-coins"></i>

<div align="center" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 1.5rem; border-radius: 12px; margin: 1rem 0;">
  <h3 style="color: white; margin: 0 0 1rem 0;"><i class="fas fa-dollar-sign"></i> Ultra-Low Cost Hosting</h3>
  <div style="font-size: 2rem; font-weight: bold; margin-bottom: 0.5rem;">< $2/month</div>
  <div style="opacity: 0.9;">For most personal sites & portfolios</div>
</div>

**Monthly cost breakdown:**
- **S3 Storage (1 GB):** $0.023
- **CloudFront (10 GB out):** $0.85 (US East prices)
- **SSL Certificate (ACM):** FREE
- **Route 53 Hosted Zone:** $0.50
- **Total: < $2/month** <i class="fas fa-dollar-sign" style="color: #28a745;"></i>

> <i class="fas fa-lightbulb" style="color: #ffc107;"></i> **Cost Note:** This assumes moderate traffic (10GB/month CloudFront data transfer). For higher traffic, costs scale linearly but remain very affordable compared to traditional hosting.

---

## Wrapping Up <i class="fas fa-trophy"></i>

<div align="center" style="background: rgba(40, 167, 69, 0.1); border: 1px solid rgba(40, 167, 69, 0.3); padding: 2rem; border-radius: 12px; margin: 2rem 0;">
  <h3 style="color: #28a745; margin-top: 0;"><i class="fas fa-rocket"></i> That's a Wrap!</h3>
  <p style="color: var(--text-color, #333);">Your Jekyll site is now running on a <strong>secure, CDN‑accelerated stack</strong> that delivers enterprise-grade performance for under $2/month.</p>
</div>

### <i class="fas fa-check-circle" style="color: #28a745;"></i> What We Built:
You’ve built a **secure, CDN‑accelerated Jekyll site** that:

- **Global reach** — CloudFront serves content from 400+ edge locations worldwide
- **Dirt cheap hosting** — Under $2/month for most personal sites
- **Zero server maintenance** — No patching, no monitoring, no headaches
- **Everything in Git** — Infrastructure and content both version controlled
- **SSL by default** — Free certificates that renew automatically

### Next Steps
- **Custom domain**: Add `www.guydevops.com` as an alias in CloudFront
- **CI/CD**: Replace the `null_resource` with GitHub Actions for automated deployments
- **Monitoring**: Add CloudWatch alarms for 4xx/5xx errors
- **Performance**: Enable Gzip compression and optimize images
- **Security**: Consider adding AWS WAF for DDoS protection

### Troubleshooting
- **CloudFront cache**: Changes may take 5-15 minutes to propagate globally
- **DNS propagation**: Route 53 changes can take up to 48 hours
- **Jekyll build errors**: Check Ruby version compatibility (3.1-3.2 recommended)

---

*Questions or run into issues? Hit me up on [GitHub](https://github.com/gpayne9) or [LinkedIn](https://linkedin.com/in/guypayne9). <i class="fas fa-rocket"></i>*

