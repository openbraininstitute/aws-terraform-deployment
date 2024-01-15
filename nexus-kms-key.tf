resource "aws_kms_key" "nexus-kms-key" {
  description             = "Nexus KMS Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "kms.amazonaws.com"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}

output "kms_key_arn" {
  value = aws_kms_key.nexus-kms-key.arn
}