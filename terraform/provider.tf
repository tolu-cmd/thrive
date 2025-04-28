terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Using version 4.x which is compatible with the VPC module
    }
  }
  required_version = ">= 1.0.0"
}
