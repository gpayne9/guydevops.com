# Guy's DevOps Site

<div align="center">

[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-623CE4?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io/)
[![Jekyll](https://img.shields.io/badge/Jekyll-CC0000?style=for-the-badge&logo=jekyll&logoColor=white)](https://jekyllrb.com/)
[![CloudFront](https://img.shields.io/badge/CloudFront-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/cloudfront/)

**A lightning-fast, globally-distributed DevOps site built with modern cloud infrastructure**

[🌐 Visit Site](https://guydevops.com) • [📖 Blog Posts](https://guydevops.com/posts/) • [👨‍💻 About](https://guydevops.com/about/)

</div>

## 🚀 Project Overview

This repository contains the source code and infrastructure for **guydevops.com** - a professional DevOps site where I share tutorials, architecture deep-dives, and real-world solutions for cloud infrastructure challenges.

### 🎯 What You'll Find Here

- **Step-by-step tutorials** for complex DevOps challenges
- **Infrastructure as Code** examples with working Terraform configurations
- **AWS architecture patterns** with practical implementations
- **Cost optimization strategies** for cloud infrastructure
- **Security best practices** and real-world implementations
- **Personal projects** and how they're built

## 🏗️ Architecture

This site demonstrates a modern, scalable static site architecture using AWS services:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudFront    │    │       S3         │    │   Route 53      │
│   (Global CDN)  │◄──►│  (Static Files)  │◄──►│   (DNS)         │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         ▲                        ▲                       ▲
         │                        │                       │
         ▼                        ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│      ACM        │    │    Jekyll        │    │   Terraform     │
│  (SSL Certs)    │    │  (Site Builder)  │    │     (IaC)       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### 🌟 Key Features

- **⚡ Lightning Fast**: CloudFront CDN with 400+ global edge locations
- **🔒 Secure**: Free SSL certificates with automatic renewal via ACM
- **💰 Cost Effective**: ~$2/month hosting costs for global distribution
- **🌍 Global**: Accessible worldwide with geo-restrictions for security
- **📱 Responsive**: Mobile-first design with dark mode support
- **🔍 SEO Optimized**: Structured data, sitemaps, and performance optimized

## 🛠️ Technology Stack

### **Frontend & Content**
- **[Jekyll](https://jekyllrb.com/)** - Static site generator
- **[Chirpy Theme](https://github.com/cotes2020/jekyll-theme-chirpy)** - Professional Jekyll theme
- **Markdown** - Content authoring
- **Liquid** - Templating engine
- **SCSS** - Styling with variables and mixins

### **Infrastructure (AWS)**
- **[Amazon S3](https://aws.amazon.com/s3/)** - Static file hosting
- **[CloudFront](https://aws.amazon.com/cloudfront/)** - Global CDN and edge caching
- **[Route 53](https://aws.amazon.com/route53/)** - DNS management
- **[ACM](https://aws.amazon.com/certificate-manager/)** - SSL certificate management
- **[IAM](https://aws.amazon.com/iam/)** - Access control and security policies

### **Infrastructure as Code**
- **[Terraform](https://terraform.io/)** - Infrastructure provisioning and management
- **[AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)** - AWS resource management
- **State Management** - Remote state storage in S3

### **Development & Deployment**
- **Ruby 3.2.2** - Jekyll runtime environment
- **Bundler** - Dependency management
- **Git** - Version control
- **GitHub** - Repository hosting
- **AWS CLI** - Deployment automation

### **Security & Performance**
- **Custom Headers** - Secure S3 access via CloudFront
- **Geo-restrictions** - Block specific high-risk regions
- **Compression** - Gzip compression for faster loading
- **Caching** - Optimized cache policies for static content

## 📁 Project Structure

```
guydevops.com/
├── _config.yml              # Jekyll configuration
├── _posts/                  # Blog posts in Markdown
├── _tabs/                   # Static pages (About, etc.)
├── _data/                   # Site data and localization
├── _includes/               # Reusable template components
├── _layouts/                # Page layouts
├── _sass/                   # SCSS stylesheets
├── assets/                  # Static assets (images, JS, CSS)
├── terraform/               # Infrastructure as Code
│   ├── main.tf             # Provider and backend configuration
│   ├── s3.tf               # S3 bucket and policies
│   ├── cloudfront.tf       # CloudFront distribution
│   └── acm_cert.tf         # SSL certificate management
├── tools/                   # Build and deployment scripts
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

- **Ruby 3.1+** (recommend 3.2.2)
- **Bundler** gem
- **AWS CLI** configured with appropriate credentials
- **Terraform** 1.0+

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/gpayne9/guydevops.com.git
   cd guydevops.com
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Start local development server**
   ```bash
   bundle exec jekyll serve
   ```

4. **Visit your local site**
   ```
   http://localhost:4000
   ```

### Deployment

1. **Build the site**
   ```bash
   bundle exec jekyll build
   ```

2. **Deploy infrastructure**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

The Terraform configuration will:
- Create S3 bucket for static hosting
- Set up CloudFront distribution with global CDN
- Configure SSL certificates via ACM
- Upload built site files to S3

## 💰 Cost Breakdown

**Monthly hosting costs for most personal sites:**

| Service                  | Cost             | Description             |
| ------------------------ | ---------------- | ----------------------- |
| **S3 Storage (1GB)**     | $0.023           | Static file storage     |
| **CloudFront (10GB)**    | $0.85            | Global CDN distribution |
| **Route 53 Hosted Zone** | $0.50            | DNS management          |
| **ACM SSL Certificate**  | FREE             | Automatic SSL/TLS       |
| **Total**                | **~$1.37/month** | Ultra-low cost hosting  |

## 🔧 Configuration

### Environment Variables

The site uses these key configuration options in `_config.yml`:

```yaml
title: Guy's DevOps Site
tagline: A site created by Guy Payne to share DevOps information, ideas, and projects
url: "guydevops.com"
```

### Terraform Variables

Key Terraform variables in `terraform/`:

```hcl
variable "secret_header" {
  description = "Secret header for S3 access control"
  type        = string
  default     = "secret-header"
}

variable "site_path" {
  description = "Local path to Jekyll site"
  type        = string
  default     = "~/repos/guydevops.com"
}
```

## 🛡️ Security Features

- **S3 Bucket Policies** - Restrict direct access, only allow CloudFront
- **Custom Headers** - Secret header validation for additional security
- **Geo-restrictions** - Block access from specific high-risk countries
- **SSL/TLS** - Automatic HTTPS with modern TLS protocols
- **Security Headers** - Content security and performance headers

## 📈 Performance Optimizations

- **Global CDN** - CloudFront edge locations worldwide
- **Compression** - Gzip compression for all text assets
- **Caching** - Optimized cache policies for static content
- **Image Optimization** - Responsive images and modern formats
- **Minification** - CSS and JavaScript minification

## 🤝 Contributing

This is a personal site, but if you find issues or have suggestions:

1. **Open an issue** to discuss the change
2. **Fork the repository**
3. **Create a feature branch**
4. **Submit a pull request**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

- **Website**: [guydevops.com](https://guydevops.com)
- **LinkedIn**: [guy-p-devops](https://www.linkedin.com/in/guy-p-devops/)
- **GitHub**: [gpayne9](https://github.com/gpayne9)
- **Email**: [guyp4@protonmail.com](mailto:guyp4@protonmail.com)

---

<div align="center">

**Built with ❤️ using Jekyll, AWS, and Terraform**

*Demonstrating modern DevOps practices through Infrastructure as Code*

</div>