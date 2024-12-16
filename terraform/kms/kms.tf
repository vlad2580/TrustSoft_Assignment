resource "aws_kms_key" "kms_key" {
  description             = "KMS Key for data encryption"
  deletion_window_in_days = 30

  tags = {
    Name        = "KMSK_internship_vladislav"
    Environment = "Production"
  }
}

output "kms_key" {
  value = aws_kms_key.kms_key.arn
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/kms-key_yurikov"
  target_key_id = aws_kms_key.kms_key.key_id
}

resource "aws_kms_key" "kms_with_policy" {
  description = "KMS Key with custom policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::863518451378:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow access for specific IAM role",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::863518451378:role/aws-controltower-AdministratorExecutionRole"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}
