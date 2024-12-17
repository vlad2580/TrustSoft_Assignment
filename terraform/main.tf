#---------------------------------------------------#
# Terraform Backend Configuration                   #
#---------------------------------------------------#

terraform {
  backend "s3" {
    bucket         = "s3-internship-vladislav"
    key            = "state/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

#---------------------------------------------------#
# AWS Provider Configuration                        #
#---------------------------------------------------#

provider "aws" {
  region = var.region
}

#---------------------------------------------------#
# Backend Module                                    #
#---------------------------------------------------#

module "backend" {
  source              = "./backend"
  region              = var.region
  s3_bucket_name      = "s3-internship-vladislav"
  dynamodb_table_name = "terraform-lock-table"
  sns_email           = var.sns_email
}



