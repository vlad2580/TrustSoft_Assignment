# output "kms_key_arn" {
#   value = aws_kms_key.ec2_ebs_key.arn
# }
output "ec2_instance_ids" {
  value = aws_instance.web_server[*].id
}

output "alb_dns_name" {
  value       = aws_lb.app_lb.dns_name
  description = "DNS Name of the Application Load Balancer"
}
