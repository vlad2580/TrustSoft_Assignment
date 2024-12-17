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

resource "aws_instance" "postgresql_server" {
  count                       = 1
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.privateSB1.id
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
    Name        = "postgresql_internship_vladislav"
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

#---------------------------------------------------#
# SSM Association                                   #
#---------------------------------------------------#

resource "aws_ssm_association" "apply_cloudwatch_agent_config" {
  name                = aws_ssm_document.custom_cloudwatch_config.name
  association_name    = "associations_internship_yurikov"
  schedule_expression = "rate(1 day)"

  targets {
    key    = "tag:Name"
    values = ["webServer1_internship_vladislav", "webServer2_internship_vladislav"]
  }
}

#---------------------------------------------------#
# SSM Document                                      # 
#---------------------------------------------------#

resource "aws_ssm_document" "custom_cloudwatch_config" {
  name          = "cwatchAgentConfig_internship_yurikov"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Custom SSM Document to configure CloudWatch Agent",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "configureCloudWatchAgent",
        inputs = {
          runCommand = [
            "wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb",
            "sudo dpkg -i -E ./amazon-cloudwatch-agent.deb",
            "sudo apt-get update && sudo apt-get install -y collectd",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${join(",", aws_ssm_parameter.cloudwatch_config[*].name)} -s",
            "sudo systemctl enable amazon-cloudwatch-agent",
            "sudo systemctl start amazon-cloudwatch-agent"
          ]
        }
      }
    ]
  })
}

#---------------------------------------------------#
# SSM Parameter                                     #
#---------------------------------------------------#

resource "aws_ssm_parameter" "cloudwatch_config" {
  count = 2
  name  = "CWatchAgentConf-internship-yurikov-${count.index}"
  type  = "String"
  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      logfile                     = "/var/log/cloudwatch-agent.log"
    }
    metrics = {
      append_dimensions = {
        InstanceId = "${aws_instance.web_server[count.index].id}"
      }
      metrics_collected = {
        disk = {
          measurement              = ["used_percent", "inodes_free"]
          resources                = ["*"]
          ignore_file_system_types = ["sysfs", "tmpfs"]
        }
        mem = {
          measurement = ["mem_used_percent"]
        }
        cpu = {
          measurement = ["cpu_usage_active"]
        }
      }
    }
  })
  overwrite = true
}
