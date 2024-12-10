output "kms_key_arn" {
  value = aws_kms_key.ec2_ebs_key.arn
}
