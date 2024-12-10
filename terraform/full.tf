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

#-------------------------------#
# Load Balancer                 #
#-------------------------------#

# Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name                       = var.alb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.allow_tls.id]
  subnets                    = [aws_subnet.publicSB1.id, aws_subnet.publicSB2.id]
  enable_deletion_protection = false

  tags = {
    Name = "alb_internship_vladislav"
  }
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "target_group_internship_vladislav"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}

#---------------------------------------------------#
# EC2 instance                                      #
#---------------------------------------------------#

resource "aws_instance" "web_server" {
  count                       = 2
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = count.index % 2 == 0 ? aws_subnet.privateSB1.id : aws_subnet.privateSB2.id
  vpc_security_group_ids      = [aws_security_group.allow_tls.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = false
  user_data                   = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "Hello from server ${count.index + 1}!" > /var/www/html/index.html
    sudo systemctl status amazon-ssm-agent

    EOT
  root_block_device {
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
    encrypted   = true
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    description = "Creates EC2 instances for the web server with Apache pre-installed"
    Name        = "webServer${count.index + 1}_internship_vladislav"
  }

}

#---------------------------------------------------#
# IAM configuration                                 #
#---------------------------------------------------#
resource "aws_iam_role" "ec2_role" {
  name = "iamrole_internship_yurikov"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_internship_profile"
  role = aws_iam_role.ec2_role.name
}

#---------------------------------------------------#
# KMS Key                                           #
#---------------------------------------------------#
# resource "aws_kms_key" "ec2_ebs_key" {
#   description              = "KMS key for encrypting EC2 root and EBS volumes"
#   key_usage                = "ENCRYPT_DECRYPT"
#   customer_master_key_spec = "SYMMETRIC_DEFAULT"
#   enable_key_rotation      = true

#   policy = <<EOF
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": {
#           "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         },
#         "Action": [
#           "kms:Create*",
#           "kms:Describe*",
#           "kms:Enable*",
#           "kms:List*",
#           "kms:Put*",
#           "kms:Update*",
#           "kms:Revoke*",
#           "kms:Disable*",
#           "kms:Get*",
#           "kms:Delete*",
#           "kms:ScheduleKeyDeletion",
#           "kms:CancelKeyDeletion"
#         ],
#         "Resource": "*"
#       },
#       {
#         "Effect": "Allow",
#         "Principal": {
#           "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         },
#         "Action": [
#           "kms:GenerateDataKey*",
#           "kms:Encrypt",
#           "kms:Decrypt"
#         ],
#         "Resource": "*"
#       }
#     ]
#   }
#   EOF

#   tags = {
#     Name = "kms_internship_vladislav"
#   }
# }

# data "aws_caller_identity" "current" {}

#---------------------------------------------------#
# Security Group                                    #
#---------------------------------------------------#
resource "aws_security_group" "allow_tls" {
  name        = var.security_group_name
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP connection"
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
# VPC configuration                                 #
#---------------------------------------------------#
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
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
