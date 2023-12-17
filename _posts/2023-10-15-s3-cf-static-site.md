---
title: Create and deploy a static site to AWS CloudFront and S3 using Terraform
author: guy
date: 2023-10-15 11:33:00 +0800
categories: [Terraform, Demo, S3, CloudFront]
tags: [typography]
pin: true
math: true
mermaid: true
---

<!-- ## Headings -->

<!-- <h1 class="mt-5">Create and deploy a static site to AWS CloudFront and S3 using Terraform</h1>

<h2 data-toc-skip>H2 - heading</h2>

### H3 — heading
{: data-toc-skip='' .mt-4 .mb-0 }

<h4>H4 - heading</h4> -->

## Intro

Are you considering creating a blazing-fast, scalable, and cost-efficient website powered by Jekyll, and deploying it using the robust infrastructure as code (IaC) capabilities of Terraform? Look no further! In this guide, I'll walk you through the steps I took to build and deploy my website, guydevops.com, leveraging the power of Terraform, Amazon S3, and CloudFront.

## The Technology Stack
<span style="font-size: larger;" >[Jekyll](https://jekyllrb.com/)
:</span>
 is a static site generator that allows you to build simple to complex websites without the need for a traditional server. Its simplicity and flexibility make it an excellent choice for blogs, portfolios, and personal websites.

<span style="font-size: larger;" >[Terraform](https://www.terraform.io/):</span> Terraform, an IaC tool by HashiCorp, enables you to define and provision infrastructure using a declarative configuration language. This means you can define your entire infrastructure in code, making it reproducible, version-controlled, and easily managed.

<span style="font-size: larger;" >[Amazon S3](https://aws.amazon.com/s3/):</span>: Amazon Simple Storage Service (S3) is a scalable object storage service. In this setup, S3 is used to host and serve the static content of the Jekyll website.

<span style="font-size: larger;" >[CloudFront](https://aws.amazon.com/cloudfront/):</span> Amazon CloudFront is a content delivery network (CDN) that securely delivers data, videos, applications, and APIs to customers globally with low-latency and high transfer speeds. CloudFront is employed to cache and distribute the website content, ensuring rapid and reliable access for users around the world.

## prerequisites

1. [Ruby 3.2.2+](https://www.ruby-lang.org/en/documentation/installation/)
2. [AWS account](https://aws.amazon.com/resources/create-account/)
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html)
4. [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
5. [git](https://git-scm.com/downloads)
6. [GitHub account](https://github.com/)
7. [AWS route53 zone and domain](https://aws.amazon.com/route53/)


## Create Jekyll blog

To start out we need to generate a static site to upload to S3. We are going to use the [Jekyll chripty theme](https://github.com/cotes2020/jekyll-theme-chirpy). This theme has a modern professional style and is easy to set up. The best part about this theme is you do not need to know almost anything on frontend web design because all you have to do is edit Markdown files to write your articles . I will go over beefily how I set up and generate the static objects and set up the development environment. I used [this YouTube video](https://www.youtube.com/watch?v=F8iOU1ci19Q) by Techno Tim as inspiration for using Chripty. We aren't going to be using the github pages feature so you can skip or ignore any part of that in the documentation.

1. Login to your GitHub account and [fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) the [Jekyll chripty theme](https://github.com/cotes2020/jekyll-theme-chirpy) or use the [Chripy starter](https://chirpy.cotes.page/posts/getting-started/#option-1-using-the-chirpy-starter) listed in their documentation. 
2. Open a terminal of your choice

3. Run `git clone https://github.com/USERNAME/REPONAME.git` (you might need to sign into github locally)

4. Run `gem install bundler jekyll` to get bundle in the directory of the repo

5. Run `bundle` to install all of the dependencies

6. To run the project locally run `bundle exec jekyll s` pull up your local host in a browser to see http://127.0.0.1:4000

7. Now that we have the project set up you can edit the values in the `_config.yml` and the `.mb` files in the `_post` directory to create articles.

## Setting up the AWS environment

This guide assumes you already have a domain purchased and a route53 zone set up. This can be done by following this [AWS documentation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html).


1. Login to the [AWS console](https://aws.amazon.com/)
1. Navigate to the [S3](https://s3.console.aws.amazon.com) service and create an S3 bucket for the Terraform state
    - We will be using a remote state backend for terraform which requires a bucket to be created outside of terraform [(Terraform documentation)](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
    - The bucket should be private and requires no additional set up
    - The bucket can be named what ever you like
1. Navigate to the [IAM](https://us-east-1.console.aws.amazon.com/) service and create an admin IAM user for your AWS CLI to have permissions

2. Run `aws configure` and input your access key, secret key and the AWS region you're working in. [(AWS documentation)](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html#getting-started-prereqs-keys)

3. Run `aws sts get-caller-identity` to confirm your CLI user is properly set up

## Setting up Terraform

All of the terraform listed can be found on my [GitHub](https://github.com/gpayne9/guydevops.com/tree/master/terraform)

1. First we need to set up the ```main.tf``` with the ```required_providers``` and the S3 back end that we set up in step 3 of Setting up the AWS environment. This is just a base terraform file that configures the provider and the s3 remote backend.

```hcl

# Configure the Terraform block
terraform {
  # Specify required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  
  # Configure the backend for remote state storage in an S3 bucket
  backend "s3" {
    bucket = "guy-terraform-state"  # Specify the name of the S3 bucket for storing Terraform state
    key    = "terraform"             # Specify the key (path) within the bucket where the state file will be stored
    region = "us-east-1"             # Specify the AWS region for the S3 bucket
  }
  
  # Specify the minimum required Terraform version
  required_version = ">= 1.2.0"
}

# Configure the AWS provider
provider "aws" {
  region = "us-east-1"  # Specify the default AWS region for resource provisioning
}

```
2. Now lets create the S3 bucket with s3 website configured. 
  - The ```aws_s3_bucket_website_configuration``` resource is what enables the index.html to be auto loaded when you navigate through the site.
  - The ```aws_s3_bucket``` has to be set to public for the S3 website configuration to work however there is a way to lock the s3 bucket down via injecting a header in the Cloud Front distribution. Here is a [StackOverflow](https://stackoverflow.com/questions/55500373/restrict-access-to-s3-static-website-behind-a-cloudfront-distribution) thread about this situation.
  - The ```secret_header``` variable can be set via either a tfvar file or [other ways of setting environment variables in terraform](https://developer.hashicorp.com/terraform/language/values/variables_). Do not commit this secret header to source control if you want it to be actually secret.
  - The site deployment to s3 is done via a ```null_resource``` block. This automates the process of copying/synching the files genreated by 

```hcl
# Define a variable for a secret header (do not commit to source control)
variable "secret_header" {
  type    = string
  default = "secret-header"
}
variable "site_path" {
  type = string
  default = "~/repos/guydevops.com"
}


# Create an S3 bucket for the website
resource "aws_s3_bucket" "guydevops-com_s3_bucket" {
  bucket = "guydevops.com"
  tags = {
    Name        = "guydevops"
    Environment = "prod"
  }
}

# Configure the S3 bucket as a website with an index document
resource "aws_s3_bucket_website_configuration" "guydevops-com_s3_bucket_website" {
  bucket = aws_s3_bucket.guydevops-com_s3_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Create an S3 bucket policy to allow public access to the site with a secret header
resource "aws_s3_bucket_policy" "allow_public_access_to_site" {
  bucket = aws_s3_bucket.guydevops-com_s3_bucket.id
  policy = data.aws_iam_policy_document.allow_public_access_to_site_policy.json
}

# Define an IAM policy document to allow public access with a specific referer header
data "aws_iam_policy_document" "allow_public_access_to_site_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:GetObject"]

    resources = [
      aws_s3_bucket.guydevops-com_s3_bucket.arn,
      "${aws_s3_bucket.guydevops-com_s3_bucket.arn}/*",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:Referer"
      values   = ["${var.secret_header}"]
    }
  }
}

resource "null_resource" "remove_and_upload_to_s3" {
  provisioner "local-exec" {
    command = "aws s3 sync ${var.site_path}/_site s3://${aws_s3_bucket.guydevops-com_s3_bucket.id}"
  }
}


```

3. Now lets create the ACM SSL certificate and use DNS validation. The ```aws_route53_zone``` can be imported via a terraform data lookup.

``` hcl
# Define a data source to get information about an existing Route 53 hosted zone
data "aws_route53_zone" "guydevops_zone" {
  name = "guydevops.com"
}

# Define an ACM (AWS Certificate Manager) certificate for guydevops.com
resource "aws_acm_certificate" "guydevops_cert" {
  domain_name       = "guydevops.com"
  validation_method = "DNS"  # Use DNS validation for the certificate

  tags = {
    Name = "guydevops.com"
  }
}

# Define Route 53 records for certificate validation
resource "aws_route53_record" "guydevops_cert_record" {
  for_each = {
    for dvo in aws_acm_certificate.guydevops_cert.domain_validation_options : dvo.domain_name => {
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

# Define ACM certificate validation
resource "aws_acm_certificate_validation" "guydevops_cert_validation" {
  certificate_arn         = aws_acm_certificate.guydevops_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.guydevops_cert_record : record.fqdn]
}

```

4. Finally lets create the CloudFront Distrubution

```hcl

# Define an AWS CloudFront distribution resource
resource "aws_cloudfront_distribution" "guydevops_cf_dis" {
  # Define the origin settings for the CloudFront distribution
  origin {
    domain_name = aws_s3_bucket_website_configuration.guydevops-com_s3_bucket_website.website_endpoint
    origin_id   = "S3Origin"

    # Configure custom origin settings for an S3 bucket
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1.2"]
    }

    # Add a custom header for the origin
    custom_header {
      name  = "Referer"
      value = var.secret_header
    }
  }

  # Enable the CloudFront distribution
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Set aliases (alternate domain names) for the distribution
  aliases = ["guydevops.com"]

  # Configure the default cache behavior for the distribution
  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Configure an ordered cache behavior for the distribution
  ordered_cache_behavior {
    path_pattern           = "/*"
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Configure the SSL certificate and protocol settings for the distribution
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.guydevops_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  # Configure restrictions for the distribution based on geo-location
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }
}

# Define an AWS Route 53 record resource for the domain
resource "aws_route53_record" "guydevops_record" {
  name    = "guydevops.com"
  type    = "A"
  zone_id = data.aws_route53_zone.guydevops_zone.zone_id

  # Configure an alias for the Route 53 record pointing to the CloudFront distribution
  alias {
    name                   = aws_cloudfront_distribution.guydevops_cf_dis.domain_name
    zone_id                = aws_cloudfront_distribution.guydevops_cf_dis.hosted_zone_id
    evaluate_target_health = false
  }
}

```

## Reverse Footnote

[^footnote]: The footnote source
[^fn-nth-2]: The 2nd footnote source


<!-- ### Ordered list

1. Firstly
2. Secondly
3. Thirdly

### Unordered list

- Chapter
  + Section
    * Paragraph

### ToDo list

- [ ] Job
  + [x] Step 1
  + [x] Step 2
  + [ ] Step 3

### Description list

Sun
: the star around which the earth orbits

Moon
: the natural satellite of the earth, visible by reflected light from the sun

## Block Quote

> This line shows the _block quote_.

## Prompts

> An example showing the `tip` type prompt.
{: .prompt-tip }

> An example showing the `info` type prompt.
{: .prompt-info }

> An example showing the `warning` type prompt.
{: .prompt-warning }

> An example showing the `danger` type prompt.
{: .prompt-danger }

## Tables

| Company                      | Contact          | Country |
|:-----------------------------|:-----------------|--------:|
| Alfreds Futterkiste          | Maria Anders     | Germany |
| Island Trading               | Helen Bennett    | UK      |
| Magazzini Alimentari Riuniti | Giovanni Rovelli | Italy   |

## Links

<http://127.0.0.1:4000>

## Footnote

Click the hook will locate the footnote[^footnote], and here is another footnote[^fn-nth-2]. -->
