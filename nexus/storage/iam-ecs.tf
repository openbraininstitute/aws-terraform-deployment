data "aws_iam_policy_document" "nexus_storage_ecs_task_assume_role_policy" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_nexus_storage_task_execution_role" {
  name               = "nexus_storage-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.nexus_storage_ecs_task_assume_role_policy.json
  tags               = { SBO_Billing = "nexus_storage" }
}

resource "aws_iam_role" "ecs_nexus_storage_task_role" {
  name               = "nexus_storage-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.nexus_storage_ecs_task_assume_role_policy.json
  tags               = { SBO_Billing = "nexus_storage" }
}

resource "aws_iam_role_policy_attachment" "nexus_storage_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_nexus_storage_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# # TODO do we need this?
# resource "aws_iam_role_policy_attachment" "ecs_nexus_storage_task_role_dockerhub_policy_attachment" {
#   count      = var.nexus_storage_ecs_number_of_containers > 0 ? 1 : 0
#   role       = aws_iam_role.ecs_nexus_storage_task_execution_role[0].name
#   policy_arn = var.dockerhub_access_iam_policy_arn
# }