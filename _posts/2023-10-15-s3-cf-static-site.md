---
title: Create and deploy a static site to AWS CloudFront and S3 using Terraform
author: Guy
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

4. Create an S3 bucket for your Terraform state file to exist  
## Setting up Terraform

All of the terraform listed can be found on my GitHub




## Filepath

Here is the `/path/to/the/file.extend`{: .filepath}.

## Code blocks

### Common

```text
This is a common code snippet, without syntax highlight and line number.
```

### Specific Language

```bash
if [ $? -ne 0 ]; then
  echo "The command was not successful.";
  #do the needful / exit
fi;
```

### Specific filename

```sass
@import
  "colors/light-typography",
  "colors/dark-typography";
```
{: file='_sass/jekyll-theme-chirpy.scss'}

## Mathematics

The mathematics powered by [**MathJax**](https://www.mathjax.org/):

$$
\begin{equation}
  \sum_{n=1}^\infty 1/n^2 = \frac{\pi^2}{6}
  \label{eq:series}
\end{equation}
$$

We can reference the equation as \eqref{eq:series}.

When $a \ne 0$, there are two solutions to $ax^2 + bx + c = 0$ and they are

$$ x = {-b \pm \sqrt{b^2-4ac} \over 2a} $$

## Mermaid SVG

```mermaid
 gantt
  title  Adding GANTT diagram functionality to mermaid
  apple :a, 2017-07-20, 1w
  banana :crit, b, 2017-07-23, 1d
  cherry :active, c, after b a, 1d
```

## Images

### Default (with caption)

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" }
_Full screen width and center alignment_

### Left aligned

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" .w-75 .normal}

### Float to left

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" .w-50 .left}
Praesent maximus aliquam sapien. Sed vel neque in dolor pulvinar auctor. Maecenas pharetra, sem sit amet interdum posuere, tellus lacus eleifend magna, ac lobortis felis ipsum id sapien. Proin ornare rutrum metus, ac convallis diam volutpat sit amet. Phasellus volutpat, elit sit amet tincidunt mollis, felis mi scelerisque mauris, ut facilisis leo magna accumsan sapien. In rutrum vehicula nisl eget tempor. Nullam maximus ullamcorper libero non maximus. Integer ultricies velit id convallis varius. Praesent eu nisl eu urna finibus ultrices id nec ex. Mauris ac mattis quam. Fusce aliquam est nec sapien bibendum, vitae malesuada ligula condimentum.

### Float to right

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" .w-50 .right}
Praesent maximus aliquam sapien. Sed vel neque in dolor pulvinar auctor. Maecenas pharetra, sem sit amet interdum posuere, tellus lacus eleifend magna, ac lobortis felis ipsum id sapien. Proin ornare rutrum metus, ac convallis diam volutpat sit amet. Phasellus volutpat, elit sit amet tincidunt mollis, felis mi scelerisque mauris, ut facilisis leo magna accumsan sapien. In rutrum vehicula nisl eget tempor. Nullam maximus ullamcorper libero non maximus. Integer ultricies velit id convallis varius. Praesent eu nisl eu urna finibus ultrices id nec ex. Mauris ac mattis quam. Fusce aliquam est nec sapien bibendum, vitae malesuada ligula condimentum.

### Dark/Light mode & Shadow

The image below will toggle dark/light mode based on theme preference, notice it has shadows.

![light mode only](/posts/20190808/devtools-light.png){: .light .w-75 .shadow .rounded-10 w='1212' h='668' }
![dark mode only](/posts/20190808/devtools-dark.png){: .dark .w-75 .shadow .rounded-10 w='1212' h='668' }

## Video

{% include embed/youtube.html id='Balreaj8Yqs' %}

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
