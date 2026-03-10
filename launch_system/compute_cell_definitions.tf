# All compute cell definitions in one place. Cell A uses this module's resources;
# other cells are static configuration.

locals {
  compute_cell_definitions = {
    cell_a = {
      vendor     = "aws"
      region     = var.aws_region
      account_id = var.account_id

      executors = {
        machine = [
          {
            vcpu_min        = 1
            vcpu_max        = 16
            memory_min      = 2
            memory_max      = 120
            type            = "machine"
            launch_type     = "FARGATE"
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = [aws_subnet.untrusted_a.id, aws_subnet.untrusted_b.id]
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.default_executor.family
          },
          {
            vcpu_min        = 1
            vcpu_max        = 16
            memory_min      = 2
            memory_max      = 120
            type            = "machine"
            launch_type     = "FARGATE"
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = [aws_subnet.untrusted_a.id, aws_subnet.untrusted_b.id]
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.inait_executor.family
          }
        ]
        cluster = []
      }
    }

    cell_b = {
      region          = "southcentralus"
      vendor          = "azure"
      subscription_id = "$${SECRET:AZ_SUBSCRIPTION_ID}"
      tenant_id       = "$${SECRET:AZ_TENANT_ID}"
      client_id       = "$${SECRET:AZ_CLIENT_ID}"
      client_secret   = "$${SECRET:AZ_CLIENT_SECRET}"

      executors = {
        machine = [
          {
            vcpu_min       = 1
            vcpu_max       = 4
            memory_min     = 2
            memory_max     = 8
            type           = "machine"
            job_name       = "default-executor"
            resource_group = "launch-system-scus-rg"
            image_type     = "default_python"
          },
          {
            vcpu_min       = 16
            vcpu_max       = 16
            memory_min     = 64
            memory_max     = 64
            type           = "machine"
            job_name       = "ultra-executor"
            resource_group = "launch-system-scus-rg"
            image_type     = "default_python"
          }
        ]

        cluster = {
          type                = "cluster"
          batch_account_url   = "$${SECRET:AZ_BATCH_ACCOUNT_URL}"
          username            = "obiuser"
          upload_blob_sas_url = "$${SECRET:AZ_UPLOAD_BLOB_SAS_URL}"
          instance_types = {
            large = "largenode"
            small = "obi-batch-pool"
          }
        }
      }
    }
  }

  compute_cell_definitions_tmpl = jsonencode(local.compute_cell_definitions)
}
