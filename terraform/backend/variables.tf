variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for Terraform state"
  default     = "s3-internship-vladislav"
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table for state locking"
  default     = "terraform-lock-table"
}

variable "environment" {
  description = "The environment name"
  default     = "development"
}

variable "sns_email" {
  description = "Email address to receive CloudWatch Alarm notifications"
  type        = string
}
