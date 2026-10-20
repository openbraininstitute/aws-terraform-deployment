# All compute cell definitions in one place

locals {
  slurmrestd_endpoint = [for e in awscc_pcs_cluster.cluster.endpoints : e if e.type == "SLURMRESTD"][0]

  executor_untrusted_subnet_ids = [
    aws_subnet.untrusted_a.id,
    aws_subnet.untrusted_b.id,
    aws_subnet.untrusted_c.id,
    aws_subnet.untrusted_d.id,
  ]

  compute_cell_definitions = {
    cell_a = {
      vendor     = "aws"
      region     = var.aws_region
      account_id = var.account_id

      executors = {
        machine = [
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 120
            type       = "machine"
            image_type = "python_3_12_compiler"
            placement = {
              type = "fargate"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.default_executor.family
          },
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 120
            type       = "machine"
            image_type = "python_3_12_inait"
            placement = {
              type = "fargate"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.inait_executor.family
          },
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 120
            type       = "machine"
            image_type = "python_3_12_openmpi5_neuron9_neurodamus"
            placement = {
              type = "fargate"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.python_3_12_openmpi5_neuron9_neurodamus_executor.family
          },
          # CPU Managed Instances (original path: local-cache hostPath only).
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 120
            type       = "machine"
            image_type = "python_3_12_compiler"
            placement = {
              type              = "ecs_managed_instances"
              capacity_provider = aws_ecs_capacity_provider.executor_cpu.name
              network_mode      = "host"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.default_executor_managed.family
          },
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 120
            type       = "machine"
            image_type = "python_3_12_inait"
            placement = {
              type              = "ecs_managed_instances"
              capacity_provider = aws_ecs_capacity_provider.executor_cpu.name
              network_mode      = "host"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.inait_executor_managed.family
          },
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 120
            type       = "machine"
            image_type = "python_3_12_openmpi5_neuron9_neurodamus"
            placement = {
              type              = "ecs_managed_instances"
              capacity_provider = aws_ecs_capacity_provider.executor_cpu.name
              network_mode      = "host"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.python_3_12_openmpi5_neuron9_neurodamus_executor_managed.family
          },
          # CPU ECS-on-EC2 ASG (additional: premounted EFS + shared/local caches, binpack).
          # Unpinned requests still prefer Fargate when multiple placements exist.
          # memory_max must fit the ASG's smallest instance (~56 GiB floor minus agent/OS
          # reserve): managed scaling will not launch a larger type for an oversized task
          # (unlike MI); those jobs stay PROVISIONING. Prefer MI/Fargate for bigger memory.
          # subnets/security_groups are schema-required but unused in host mode (instance SG applies).
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 54
            type       = "machine"
            image_type = "python_3_12_compiler"
            placement = {
              type              = "ecs_ec2"
              capacity_provider = aws_ecs_capacity_provider.executor_cpu_ec2.name
              network_mode      = "host"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.default_executor_ec2.family
          },
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 54
            type       = "machine"
            image_type = "python_3_12_inait"
            placement = {
              type              = "ecs_ec2"
              capacity_provider = aws_ecs_capacity_provider.executor_cpu_ec2.name
              network_mode      = "host"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.inait_executor_ec2.family
          },
          {
            vcpu_min   = 1
            vcpu_max   = 16
            memory_min = 2
            memory_max = 54
            type       = "machine"
            image_type = "python_3_12_openmpi5_neuron9_neurodamus"
            placement = {
              type              = "ecs_ec2"
              capacity_provider = aws_ecs_capacity_provider.executor_cpu_ec2.name
              network_mode      = "host"
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.python_3_12_openmpi5_neuron9_neurodamus_executor_ec2.family
          },
          # GPU Managed Instances.
          {
            vcpu_min   = 16
            vcpu_max   = 16
            memory_min = 64
            memory_max = 64
            type       = "machine"
            image_type = "python_3_12_compiler_cuda_12_8"
            placement = {
              type              = "ecs_managed_instances"
              capacity_provider = aws_ecs_capacity_provider.executor_gpu.name
            }
            cluster_name    = aws_ecs_cluster.executor.name
            subnets         = local.executor_untrusted_subnet_ids
            security_groups = [aws_security_group.executor.id]
            task_family     = aws_ecs_task_definition.python_3_12_compiler_cuda_12_8_executor.family
          },
        ]

        cluster = {
          type                 = "cluster"
          username             = "obiuser"
          uid                  = 4000
          gid                  = 4000
          homedir              = "/data/scratch/obiuser"
          slurm_url            = "http://${local.slurmrestd_endpoint.private_ip_address}:6820/slurm/v0.0.43"
          slurm_accounting_url = "http://${local.slurmrestd_endpoint.private_ip_address}:6820/slurmdb/v0.0.43"
          slurm_secret         = "$${SECRET:SLURM_SECRET}"
          instance_types = {
            small = [awscc_pcs_queue.pcs_queue_small.name]
            large = [awscc_pcs_queue.pcs_queue_large.name]
            #large = concat([awscc_pcs_queue.pcs_queue_large.name],
            #[for k, q in awscc_pcs_queue.pcs_queue_large_fallback : q.name])
          }
        }
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
            image_type     = "python_3_12_compiler"
          },
          {
            vcpu_min       = 16
            vcpu_max       = 16
            memory_min     = 64
            memory_max     = 64
            type           = "machine"
            job_name       = "ultra-executor"
            resource_group = "launch-system-scus-rg"
            image_type     = "python_3_12_compiler"
          }
        ]

        cluster = {
          type                = "cluster"
          batch_account_url   = "$${SECRET:AZ_BATCH_ACCOUNT_URL}"
          username            = "obiuser"
          upload_blob_sas_url = "$${SECRET:AZ_UPLOAD_BLOB_SAS_URL}"
          instance_types = {
            large = ["large"]
            small = ["small"]
          }
        }
      }
    }
  }

  compute_cell_definitions_tmpl = jsonencode(local.compute_cell_definitions)
}
