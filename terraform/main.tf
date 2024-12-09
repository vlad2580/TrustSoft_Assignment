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


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.region
  tags = {
    Name = "PublicSubnet"
  }
}
