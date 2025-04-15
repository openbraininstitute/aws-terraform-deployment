echo "Terraform plan for NSE sandbox"

terraform plan \
    -target=module.obi_one_svc \
    -target=module.obi_generative_gui \
    -target=aws_ecs_service.obi_one_ecs_service \
    -target=aws_ecs_service.obi_generative_gui_ecs_service \
    -var-file=sandbox-nse.tfvars \
    -out plan.tfplan && terraform show plan.tfplan
