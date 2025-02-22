terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.83.1"
    }
  }
backend "s3" {
    bucket         = "totobucket-terraform-state-bucket1"
    key            = "terraform/state"
    region         = "us-east-1"
    dynamodb_table = "toto_table" # toto
  }
}

provider "aws" {
  region = "us-east-1" 
}