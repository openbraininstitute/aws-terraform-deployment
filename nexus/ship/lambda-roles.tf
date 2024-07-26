resource "aws_iam_role" "nexus_ship_lambda" {
  name = "nexus_ship-lambdaRole"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "nexus_ship_pass_role" {
  name        = "NexusShipPassRole"
  description = "Allows to pass the given role to the Nexus ECS roles."

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : [
          aws_iam_role.nexus_ship_ecs_task.arn,
          var.ecs_task_execution_role_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "run_ship_ecs_task" {
  name        = "NexusRunShipECSTask"
  description = "Allows to pass the given role to the Nexus ECS roles."

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecs:RunTask"
        ],
        "Resource" : [
          "${aws_ecs_task_definition.nexus_ship.arn_without_revision}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.nexus_ship_lambda.arn
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.nexus_ship_lambda.arn
}

resource "aws_iam_role_policy_attachment" "nexus_ship_pass_role" {
  policy_arn = aws_iam_policy.nexus_ship_pass_role.arn
  role       = aws_iam_role.nexus_ship_lambda.arn
}

resource "aws_iam_role_policy_attachment" "run_ship_ecs_task" {
  policy_arn = aws_iam_policy.run_ship_ecs_task.arn
  role       = aws_iam_role.nexus_ship_lambda.arn
}