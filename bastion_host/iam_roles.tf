

# Define user groups and their permissions
locals {
  user_groups = {
    obi_users = {
      users = [
        { username = "bilal.meddah", email = "bilal.meddah@openbraininstitute.org" },
        { username = "boris.bergsma", email = "boris.bergsma@openbraininstitute.org" },
        { username = "eleftherios.zisis", email = "eleftherios.zisis@openbraininstitute.org" },
        { username = "georges.khazen", email = "georges.khazen@openbraininstitute.org" },
        { username = "gianluca.ficarelli", email = "gianluca.ficarelli@openbraininstitute.org" },
        { username = "jan.krepl", email = "jan.krepl@openbraininstitute.org" },
        { username = "jean-denis.courcol", email = "jean-denis.courcol@openbraininstitute.org" },
        { username = "juanjose.garcia", email = "juanjose.garcia@openbraininstitute.org" },
        { username = "mgevaert", email = "mgevaert@openbraininstitute.org" },
        { username = "nicolas.frank", email = "nicolas.frank@openbraininstitute.org" },
        { username = "pavlo.getta", email = "pavlo.getta@openbraininstitute.org" },
      ]
      sudo_access = false
    }
    obi_administrators = {
      users = [
        { username = "daniel.fernandez", email = "daniel.fernandez@openbraininstitute.org" },
        { username = "dries.verachtert", email = "dries.verachtert@openbraininstitute.org" },
        { username = "erik.heeren", email = "erik.heeren@openbraininstitute.org" },
      ]
      sudo_access = true
    }
  }

  # Flatten the user list
  all_users = flatten([
    for group, config in local.user_groups : [
      for user in config.users : {
        username = user.username
        email    = user.email
        group    = group
        sudo     = config.sudo_access
      }
    ]
  ])
}

# Create IAM role for EC2 instances
resource "aws_iam_role" "ssm_instance_role" {

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "SSM-Instance-Role"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_instance_role.name
}

# Attach policy for S3 session logging
resource "aws_iam_role_policy" "session_logging_policy" {
  name = "session-logging-policy"
  role = aws_iam_role.ssm_instance_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:PutObjectAcl",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "${aws_s3_bucket.session_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "${aws_s3_bucket.session_logs.arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.session_logs.arn}",
          "${aws_cloudwatch_log_group.session_logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "kms_policy" {
  name = "kms-policy"
  role = aws_iam_role.ssm_instance_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.cloudwatch_logs.arn
      }
    ]
  })
}
