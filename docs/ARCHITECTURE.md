# guydevops.com — Architecture & Setup

Personal DevOps blog by Guy Payne. Jekyll static site served from AWS S3 behind CloudFront, provisioned with Terraform, deployed via GitHub Actions.

Live at: https://guydevops.com

---

## Repo Structure

```
guydevops.com/
├── _config.yml                  # Jekyll + Chirpy theme configuration
├── _posts/                      # Blog articles (Markdown)
├── _tabs/                       # Static pages: about, archives, categories, tags
├── _data/
│   ├── authors.yml              # Author metadata
│   ├── contact.yml              # Sidebar contact links
│   └── share.yml                # Social sharing options
├── _plugins/
│   └── posts-lastmod-hook.rb    # Sets post last-modified from git history
├── assets/img/
│   ├── guy.jpeg                 # Profile avatar
│   ├── cloud.png                # Custom graphic
│   └── favicons/                # Site favicons (all sizes)
├── terraform/
│   ├── main.tf                  # Provider config, remote state backend
│   ├── s3.tf                    # S3 bucket, website config, deploy provisioner
│   ├── cloudfront.tf            # CDN distribution, Route 53 DNS record
│   └── acm_cert.tf              # TLS certificate with DNS validation
├── .github/workflows/
│   ├── ci.yml                   # Build & deploy pipeline (Jekyll → S3 → CloudFront)
│   └── codeql.yml               # Security scanning for JS
├── tools/
│   ├── test.sh                  # Local build + html-proofer validation
│   └── run.sh                   # Local development server
├── Gemfile                      # Ruby deps: chirpy theme gem, jekyll-spaceship, html-proofer
├── index.html                   # Homepage (layout: home)
├── .gitignore
├── README.md
└── LICENSE
```

---

## Blog Framework

**Jekyll** with the **Chirpy theme** consumed as a Ruby gem (`jekyll-theme-chirpy ~> 7.4`).

The theme provides all layouts, includes, sass, and JS. This repo only contains content and configuration — no theme source code. To customize a theme file, drop an override in the matching path (e.g., `_layouts/post.html` to override the post layout).

### Key config values (_config.yml)

| Setting | Value |
|---|---|
| Theme | `jekyll-theme-chirpy` |
| Language | `en` |
| Timezone | `America/New_York` |
| URL | `guydevops.com` |
| Avatar | `assets/img/guy.jpeg` |
| Author | Guy Payne |
| Pagination | 10 posts per page |
| PWA | Enabled with offline cache |

### Plugins

- **jekyll-seo-tag** — SEO meta tags (bundled with Chirpy)
- **jekyll-spaceship** — Enhanced table rendering, Mermaid support
- **posts-lastmod-hook.rb** — Custom plugin that reads git history to set `last_modified_at` on posts

### Theme Updates

```bash
bundle update jekyll-theme-chirpy
```

---

## AWS Infrastructure

All infrastructure is in `us-east-1` (required for CloudFront + ACM).

### Resources

| Resource | Purpose | Terraform File |
|---|---|---|
| S3 Bucket (`guydevops.com`) | Static file hosting | `s3.tf` |
| CloudFront Distribution (`E16HINOP0APRBN`) | Global CDN, HTTPS termination | `cloudfront.tf` |
| Route 53 A Record | DNS alias to CloudFront | `cloudfront.tf` |
| ACM Certificate | TLS for guydevops.com, auto-renewing | `acm_cert.tf` |
| S3 Bucket (`guy-terraform-state`) | Terraform remote state | `main.tf` (backend) |

### Access Control

The S3 bucket is not publicly accessible by default. CloudFront injects a secret `Referer` header on every origin request, and the bucket policy only allows `s3:GetObject` when that header is present. This prevents direct bucket access while avoiding the complexity of an Origin Access Identity.

### Terraform State

Stored in a separate S3 bucket (`guy-terraform-state`) with versioning enabled. State key: `terraform`.

### Geo-Restrictions

CloudFront blocks traffic from: Russia, China, North Korea, Iran.

### Cost

~$1.50/month (S3 storage + CloudFront transfer + Route 53 hosted zone). ACM certificates are free.

---

## CI/CD Pipeline

### Deploy Workflow (`.github/workflows/ci.yml`)

**Trigger:** Push to `master` (ignores README, LICENSE, terraform/**, .gitignore)

**Steps:**
1. Checkout with full git history (needed for post lastmod dates)
2. Setup Ruby 3.2.2 with bundler cache
3. `JEKYLL_ENV=production bundle exec jekyll build`
4. Assume AWS IAM role via OIDC (no static credentials)
5. `aws s3 sync _site/ s3://guydevops.com --delete`
6. Invalidate CloudFront cache (`/*`)

### AWS Authentication (OIDC)

GitHub Actions authenticates to AWS using OpenID Connect — no static access keys exist anywhere.

**How it works:**
1. GitHub generates a short-lived JWT for each workflow run
2. The JWT contains claims like `repo:gpayne9/guydevops.com:ref:refs/heads/master`
3. AWS STS verifies the JWT signature against GitHub's OIDC provider
4. If the claims match the IAM role's trust policy, temporary credentials are issued

**AWS resources:**
- OIDC Provider: `arn:aws:iam::060479073038:oidc-provider/token.actions.githubusercontent.com`
- IAM Role: `arn:aws:iam::060479073038:role/guydevops-github-deploy`

**Role trust policy** restricts access to:
- Audience: `sts.amazonaws.com`
- Subject: `repo:gpayne9/guydevops.com:ref:refs/heads/master` (this repo, master branch only)

**Role permissions (least privilege):**
- `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket` on `arn:aws:s3:::guydevops.com`
- `cloudfront:CreateInvalidation` on distribution `E16HINOP0APRBN`

No other repo, branch, or GitHub user can assume this role.

### CodeQL Workflow (`.github/workflows/codeql.yml`)

Runs GitHub's CodeQL security analysis on JavaScript file changes.

---

## Local Development

### Prerequisites

- Ruby 3.2.2 (3.3+ has stdlib changes that break Jekyll 4.x)
- Bundler

### Setup

```bash
bundle install
```

### Run locally

```bash
bundle exec jekyll serve
# Site available at http://127.0.0.1:4000
```

Or use the helper script:

```bash
bash tools/run.sh
```

### Build & validate

```bash
JEKYLL_ENV=production bundle exec jekyll build
bash tools/test.sh   # builds + runs html-proofer
```

---

## Writing a New Post

1. Create a file in `_posts/` named `YYYY-MM-DD-slug-here.md`
2. Add frontmatter:

```yaml
---
title: "Your Post Title"
description: "Short description for SEO and previews."
date: YYYY-MM-DD
tags: [Tag1, Tag2, Tag3]
categories: [Category1, Category2]
---
```

3. Optional frontmatter for special features:
   - `mermaid: true` — enables Mermaid diagrams
   - `math: true` — enables MathJax
   - `image: path/to/image.png` — post thumbnail
   - `pin: true` — pins post to homepage

4. Write content in Markdown. Code blocks use triple backticks with language identifier.

5. Preview locally with `bundle exec jekyll serve`

6. Push to `master` — GitHub Actions builds and deploys automatically.

---

## Manual Deployment (Terraform)

If you need to deploy without CI (e.g., first-time setup or infrastructure changes):

```bash
jekyll build
cd terraform
terraform init
terraform plan
terraform apply
```

The `null_resource` in `s3.tf` syncs `_site/` to S3 on every `terraform apply`. This is a fallback — normal deploys go through GitHub Actions.

---

## Important Notes

- **No theme source code in this repo.** Layouts, includes, sass, and JS come from the `jekyll-theme-chirpy` gem. Override by placing files at the same path.
- **Favicons** are in `assets/img/favicons/`. Generate new ones at [realfavicongenerator.net](https://realfavicongenerator.net/) if you change the site icon.
- **The `_site/` directory** is gitignored. It's the build output — never commit it.
- **Gemfile.lock** is gitignored. It gets generated by `bundle install` and varies by platform.
- **Terraform state** is remote (S3). Never store `.tfstate` files locally or in git.
