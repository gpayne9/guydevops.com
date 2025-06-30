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
    bucket = "guy-terraform-state" # Specify the name of the S3 bucket for storing Terraform state
    key    = "terraform"           # Specify the key (path) within the bucket where the state file will be stored
    region = "us-east-1"           # Specify the AWS region for the S3 bucket
  }

  # Specify the minimum required Terraform version
  required_version = ">= 1.2.0"
}

# Configure the AWS provider
provider "aws" {
  region = "us-east-1" # Specify the default AWS region for resource provisioning
}
