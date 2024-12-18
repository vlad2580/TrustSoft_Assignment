#---------------------------------------------------#
# VPC Flow Logs                                     #
#---------------------------------------------------#

data "aws_caller_identity" "current" {}

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
