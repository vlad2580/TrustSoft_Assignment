#---------------------------------------------------#
# Basic Configuration                               #
#---------------------------------------------------#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

}

provider "aws" {
  region = var.region
}

#---------------------------------------------------#
# VPC & Subnet configuration                        #
#---------------------------------------------------#
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MainVPC"
  }
}
