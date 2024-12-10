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
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = aws_kms_key.ec2_ebs_key.arn
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "webServer${count.index + 1}_internship_vladislav"
  }

}

#---------------------------------------------------#
# IAM configuration                                 #
# #---------------------------------------------------#
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
resource "aws_kms_key" "ec2_ebs_key" {
  description              = "KMS key for encrypting EC2 root and EBS volumes"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action": [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action": [
          "kms:GenerateDataKey*",
          "kms:Encrypt",
          "kms:Decrypt"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF

  tags = {
    Name = "kms_internship_vladislav"
  }
}

data "aws_caller_identity" "current" {}
