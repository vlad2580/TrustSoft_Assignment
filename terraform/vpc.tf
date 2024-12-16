#---------------------------------------------------#
# VPC configuration                                 #
#---------------------------------------------------#
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true
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

#---------------------------------------------------#
# VPC Flow Logs                                     #
#---------------------------------------------------#

# Получение текущего идентификатора аккаунта
data "aws_caller_identity" "current" {}

# CloudWatch Log Group with 3-day retention (приближенное значение к 2 дням)
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 3
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
          }
        }
      }
    ]
  })
}

# Attach necessary permissions for Flow Logs to send logs to CloudWatch
resource "aws_iam_policy" "vpc_flow_logs_policy" {
  name        = "VPCFlowLogsPolicy"
  description = "Policy for VPC Flow Logs to send data to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "vpc_flow_logs_policy_attachment" {
  role       = aws_iam_role.vpc_flow_logs_role.name
  policy_arn = aws_iam_policy.vpc_flow_logs_policy.arn
}

# Create VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
}
