echo "Terraform plan for HPC sandbox"

terraform plan -target="module.public_data_sync_opendata" \
               -target="module.public_data_efs_storage" \
               -var-file=sandbox-hpc.tfvars \
               -out plan.tfplan  && terraform show plan.tfplan
