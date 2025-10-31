resource "aws_guardduty_detector" "obi" {
  enable = var.is_enabled
  tags = {
    SBO_Billing = "guardduty"
  }
}

resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "ebs_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "rds_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "lambda_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "eks_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "runtime_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"
}
