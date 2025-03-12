echo "Terraform plan for NSE sandbox"

terraform plan -target="module.entitycore_svc" \
               -target=aws_db_instance.entitycore \
              -target=aws_ecs_service.entitycore_ecs_service \
               -var-file=sandbox-nse.tfvars \
               -out plan.tfplan  && terraform show plan.tfplan
