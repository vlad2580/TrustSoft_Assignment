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
    ${file("${path.module}/data/ec2_setup.sh")}
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

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_internship_profile"
  role = aws_iam_role.ec2_role.name
}

#---------------------------------------------------#
# SNS Topic for CloudWatch Alarm                    #
#---------------------------------------------------#

resource "aws_sns_topic" "cloudwatch_alarm_topic" {
  name = "cloudwatch-ec2-alarms-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.sns_email
}



#---------------------------------------------------#
# CloudWatch Alarm                                  #
#---------------------------------------------------#

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  count                     = length(aws_instance.web_server)
  alarm_name                = "cpu-utilization-${element(aws_instance.web_server[*].id, count.index)}"
  alarm_description         = "Monitors CPU utilization for EC2 instance ${element(aws_instance.web_server[*].id, count.index)}"
  namespace                 = "AWS/EC2"
  metric_name               = "CPUUtilization_internship_Yurikov"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 80
  evaluation_periods        = 2
  period                    = 60
  statistic                 = "Average"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudwatch_alarm_topic.arn]
  ok_actions                = [aws_sns_topic.cloudwatch_alarm_topic.arn]

  dimensions = {
    InstanceId = element(aws_instance.web_server[*].id, count.index)
  }
  tags = {
    Name = "cloudwtach_internship_yurikov"
  }
}
