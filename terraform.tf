locals {
  tags = {
    Terraform    = true
    "${var.instance}" = true
  }
}

terraform {
  backend "local" {}
  required_providers {
    aws = {
      version = "~> 4.59.0"
    }
  }
  
}

provider "aws" {
  region = "us-east-1"
}

