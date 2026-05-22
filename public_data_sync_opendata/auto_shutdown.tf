data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "datasync_agent_shutdown_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

locals {
  package_url           = "https://github.com/openbraininstitute/cloud-functions/releases/download/${var.agent_vm_shutdown_version}/datasync-agent-vm-shutdown.zip"
  agent_vm_shutdown_zip = "datasync-agent-vm-shutdown${md5(local.package_url)}.zip"
}

resource "null_resource" "download_package" {
  triggers = {
    downloaded = local.agent_vm_shutdown_zip
  }

  provisioner "local-exec" {
    command = "curl -L -o ${local.agent_vm_shutdown_zip} ${local.package_url}"
  }
}


resource "aws_lambda_function" "datasync_agent_shutdown" {
  filename      = local.agent_vm_shutdown_zip
  function_name = "datasync_agent_shutdown"
  role          = aws_iam_role.datasync_agent_shutdown_role.arn
  handler       = "lambda_function.handler"
  # code_sha256   = data.archive_file.datasync_agent_shutdown_code.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      OPENDATA_TASK_ARN             = aws_datasync_task.opendata_s3_to_azure_nfs.arn
      INTERNAL_PUBLIC_DATA_TASK_ARN = aws_datasync_task.internal_s3_to_azure_nfs.arn
      AZURE_CLIENT_ID               = var.azure_agent_shutdown_client_id
      AZURE_TENANT_ID               = var.azure_tenant_id
      AZURE_CLIENT_SECRET           = var.azure_agent_shutdown_client_secret
      AZURE_SUBSCRIPTION_ID         = var.azure_subscription_id
      AZURE_RESOURCE_GROUP_NAME     = var.azure_resource_group_name
    }
  }
}

resource "aws_cloudwatch_event_rule" "shutdown_agent" {
  name        = "azure_datasync_task_done"
  description = "Shut down Azure Agent VM on task completion"

  event_pattern = jsonencode({
    "source" : ["aws.datasync"],
    "detail-type" : ["DataSync Task Execution State Change"],
    "detail" : {
      "State" : ["SUCCESS", "ERROR"]
    }
  })
}

resource "aws_cloudwatch_event_target" "shutdown_agent" {
  rule      = aws_cloudwatch_event_rule.shutdown_agent.name
  target_id = "AgentShutdownLambda"
  arn       = aws_lambda_function.datasync_agent_shutdown.arn
  input     = jsonencode({ "JOB_NAME" : "" })
}
