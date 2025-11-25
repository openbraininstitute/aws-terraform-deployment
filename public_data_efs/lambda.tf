data "archive_file" "manage_datasync_source" {
  type        = "zip"
  source_file = "${path.module}/src/manage_datasync_source.py"
  output_path = "${path.module}/src/manage_datasync_source.zip"
}

resource "aws_lambda_function" "datasync_manager" {
  filename         = data.archive_file.manage_datasync_source.output_path
  source_code_hash = data.archive_file.manage_datasync_source.output_base64sha256
  function_name    = "datasync_source_manager"
  role             = aws_iam_role.lambda_role.arn
  handler          = "manage_datasync_source.lambda_handler"
  runtime          = "python3.13"
  timeout          = 300
  memory_size      = 128

  environment {
    variables = {
      S3_BUCKET_ROLE_ARN       = aws_iam_role.datasync_s3_role.arn
      DESTINATION_LOCATION_ARN = aws_datasync_location_efs.opendata_destination.arn
      BUCKET_NAME              = var.open_data_bucket
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "datasync_manager_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy" "datasync_lambda_policy" {
  name = "datasync_lambda_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListDatasyncLocations"
        Effect = "Allow"
        Action = [
          "datasync:ListLocations",
          "datasync:ListTasks"
        ]
        Resource = [
          "arn:aws:datasync:us-east-1:${var.account_id}:*"
        ]
      },
      {
        Sid    = "CreateDatasyncLocations"
        Effect = "Allow"
        Action = [
          "datasync:CreateLocationS3",
          "datasync:CreateTask",
          "datasync:DescribeTask",
          "datasync:DeleteLocation",
          "datasync:DeleteTask",
          "datasync:TagResource"
        ]
        Resource = [
          "arn:aws:datasync:us-east-1:${var.account_id}:location/*",
          "arn:aws:datasync:us-east-1:${var.account_id}:task/*"
        ]
      },
      {
        Sid    = "PassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.datasync_s3_role.arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "datasync.amazonaws.com"
          }
        }
      },
      {
        Sid    = "EC2Permissions"
        Effect = "Allow"
        Action = [
          "ec2:*VpcEndpoint*",
          "ec2:*Subnet*",
          "ec2:*SecurityGroup*",
          "ec2:*NetworkInterface*"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}
