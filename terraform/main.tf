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
    Name = "vpc_internship_vladislav"
  }
}


resource "aws_subnet" "publicSB" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "publicSubnet_internship_vladislav"
  }
}

resource "aws_subnet" "privateSB1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "privateSubnet1_internship_vladislav"
  }
}

resource "aws_subnet" "privateSB2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-1b"
  tags = {
    Name = "privateSubnet2_internship_vladislav"
  }
}

#---------------------------------------------------#
# Security Group                                    #
#---------------------------------------------------#
resource "aws_security_group" "allow_tls" {
  name        = "sg_internship_vladislav"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_internship_vladislav"
  }
}


#---------------------------------------------------#
# EC2 instance                                      #
#---------------------------------------------------#

resource "aws_instance" "web_server" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element([aws_subnet.privateSB1.id, aws_subnet.privateSB2.id], count.index)
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  tags = {
    Name = "webServer${count.index + 1}_internship_vladislav"
  }
}
