terraform {
  required_version = ">= 1.1.9"
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.11.0"
    }
  }
}
