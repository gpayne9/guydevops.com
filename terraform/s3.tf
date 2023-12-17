# Define a variable for a secret header (do not commit to source control)
variable "secret_header" {
  type    = string
  default = "secret-header"
}

# Define a variable for the path to the site content
variable "site_path" {
  type    = string
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

# Use a null resource to execute a local command for syncing site content to S3
resource "null_resource" "remove_and_upload_to_s3" {
  # Triggers determine when the null resource should be recreated.
  # In this case, we use a timestamp as a trigger to ensure the null resource
  # runs its provisioners every time "terraform apply" is executed.
   triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    #Use the AWS CLI to sync the local site content to the S3 bucket
    command = "aws s3 sync ${pathexpand(var.site_path)}/_site s3://${aws_s3_bucket.guydevops-com_s3_bucket.id}"
  }
}
