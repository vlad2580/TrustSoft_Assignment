#---------------------------------------------------#
# Basic Configuration                               #
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
module "backend" {
  source              = "./backend"
  region              = var.region
  s3_bucket_name      = "s3-internship-vladislav"
  dynamodb_table_name = "terraform-lock-table"
}

provider "aws" {
  region = var.region
}

#---------------------------------------------------#
# VPC configuration                                 #
#---------------------------------------------------#
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_internship_vladislav"
  }
}


#---------------------------------------------------#
# Internet Gateway configuration                    #
#---------------------------------------------------#
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw_internship_vladislav"
  }
}

#---------------------------------------------------#
# NAT configuration                                 #
#---------------------------------------------------#
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "nat_eip_internship_vladislav"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.publicSB1.id
  depends_on    = [aws_eip.nat_eip]
  tags = {
    Name = "nat_gateway_internship_vladislav"
  }
}

#-------------------------------#
# Route Tables & Routes         #
#-------------------------------#

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rt_public_internship_vladislav"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_nat_gateway.ngw]
}

resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.publicSB1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.publicSB2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rt_private_internship_vladislav"
  }
}
# Add public subnet association
resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.privateSB1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.privateSB2.id
  route_table_id = aws_route_table.private.id
}

#---------------------------------------------------#
# Subnet configuration                              #
#---------------------------------------------------#
resource "aws_subnet" "publicSB1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "publicSubnet1_internship_vladislav"
  }
}

resource "aws_subnet" "publicSB2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = true #delete after
  availability_zone       = "eu-west-1b"
  tags = {
    Name = "publicSubnet2_internship_vladislav"
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
    description = "SSH from specific IP"
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
  count                       = 2
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = count.index % 2 == 0 ? aws_subnet.publicSB1.id : aws_subnet.publicSB2.id
  vpc_security_group_ids      = [aws_security_group.allow_tls.id]
  associate_public_ip_address = true
  user_data                   = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "Hello from server ${count.index + 1}!" > /var/www/html/index.html

    EOT
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  tags = {
    Name = "webServer${count.index + 1}_internship_vladislav"
  }
}

#---------------------------------------------------#
# EC2 instance                                      #
#---------------------------------------------------#
# resource "aws_iam_role" "ec2_role" {
#   name = "iamrole_internship_yurikov"

#   assume_role_policy = jsonencode({
#     Version = "2024-12-11",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }
# resource "aws_iam_role_policy_attachment" "ec2_policy" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   name = "ec2_internship_profile"
#   role = aws_iam_role.ec2_role.name
# }
