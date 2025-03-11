echo "Terraform plan for NSE sandbox"

terraform plan -target="module.entitycore_svc" \
               -var-file=sandbox-nse.tfvars \
               -out plan.tfplan  && terraform show plan.tfplan
