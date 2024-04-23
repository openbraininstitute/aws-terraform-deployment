resource "aws_iam_role" "datasync_s3_role" {
  name = "datasync-s3-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "datasync.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "datasync_s3_policy" {
  name        = "datasync-s3-policy"
  description = "Policy for DataSync to access S3 bucket"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AWSDataSyncS3BucketPermissions",
        "Effect": "Allow",
        "Action": [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ],
        "Resource": "arn:aws:s3:::cs-keycloak-bucket",
        "Condition": {
          "StringEquals": {
            "aws:ResourceAccount": "992382665735"
          }
        }
      },
      {
        "Sid": "AWSDataSyncS3ObjectPermissions",
        "Effect": "Allow",
        "Action": [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectTagging"
        ],
        "Resource": "arn:aws:s3:::cs-keycloak-bucket/*",
        "Condition": {
          "StringEquals": {
            "aws:ResourceAccount": "992382665735"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datasync_s3_policy_attachment" {
  role       = aws_iam_role.datasync_s3_role.name
  policy_arn = aws_iam_policy.datasync_s3_policy.arn
}

### IAM roles and policies needed for keyloak-task logging
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}



#### We need to attach both policies to the role task_execution_role. The same role should execute the task and fetch secrets from secret manager (db password)

resource "aws_iam_policy_attachment" "ecs_task_execution_role_attachment" {
  name       = "ecs-task-execution-role-attachment"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy_attachment" "secret_access_role_attachment" {
  name       = "ecs-access-secrets-role-attachment"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
