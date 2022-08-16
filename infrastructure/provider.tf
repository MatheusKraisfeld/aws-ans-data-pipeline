provider "aws" {
  region = var.aws_region
}

# backend
terraform {
  backend "s3" {
    bucket = "terraform-state-741358071637"
    key    = "aws-ans-data-pipeline/terraform.tfstate"
    region = "us-east-1"
  }
}
