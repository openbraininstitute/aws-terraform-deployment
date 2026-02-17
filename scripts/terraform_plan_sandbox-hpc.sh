echo "Terraform plan for HPC sandbox"

terraform plan -target="module.hpc.module.vpc" \
               -target="module.hpc.module.security" \
               -target="module.hpc.module.networking" \
               -target="module.hpc.module.resource-provisioner" \
               -target="module.hpc.module.dynamodb" \
               -target="module.hpc.module.s3" \
               -target="module.hpc.module.efs" \
               -target="module.coreservices_key" \
               -target="aws_apigatewayv2_api.this" \
               -target="module.github_ami_build_role" \
               -var-file=sandbox-hpc.tfvars \
               -out plan.tfplan  && terraform show plan.tfplan
