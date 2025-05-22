locals {
  tags = {
    Terraform    = true
    "${var.instance}" = true
  }
}

provider "aws" {
  region = "us-east-1"
}
terraform {
  backend "s3" {
    region = "us-east-1"
  }
}

