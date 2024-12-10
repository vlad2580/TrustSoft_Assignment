provider "aws" {
  region = var.region
}

#---------------------------------------------------#
# S3 Bucket for backend                             #
#---------------------------------------------------#
resource "aws_s3_bucket" "tf_state" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "terraform_state_bucket"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

#---------------------------------------------------#
# DynamoDB for state lock                           #
#---------------------------------------------------#
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform_lock_table"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}
