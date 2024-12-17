# output "kms_key_arn" {
#   value = aws_kms_key.ec2_ebs_key.arn
# }
output "ec2_instance_ids" {
  description = "IDs of created EC2 instances"

  value = aws_instance.web_server[*].id
}

output "alb_dns_name" {
  value       = aws_lb.app_lb.dns_name
  description = "DNS Name of the Application Load Balancer"
}


output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.publicSB1.id, aws_subnet.publicSB2.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.privateSB1.id, aws_subnet.privateSB2.id]
}

output "ssm_association_id" {
  description = "ID созданной SSM Association"
  value       = aws_ssm_association.apply_cloudwatch_agent_config.id
}
