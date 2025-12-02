resource "aws_guardduty_detector" "obi" {
  enable = var.is_enabled
  tags = {
    SBO_Billing = "guardduty"
  }
}

resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "S3_DATA_EVENTS"
  status      = var.is_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "ebs_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = var.is_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "rds_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "RDS_LOGIN_EVENTS"
  status      = var.is_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "lambda_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "LAMBDA_NETWORK_LOGS"
  status      = var.is_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "eks_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "EKS_AUDIT_LOGS"
  status      = var.is_enabled ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "runtime_protection" {
  detector_id = aws_guardduty_detector.obi.id
  name        = "RUNTIME_MONITORING"
  status      = var.is_enabled ? "ENABLED" : "DISABLED"

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = var.is_enabled ? "ENABLED" : "DISABLED"
  }
  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = var.is_enabled ? "ENABLED" : "DISABLED"
  }
  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = var.is_enabled ? "ENABLED" : "DISABLED"
  }
}
