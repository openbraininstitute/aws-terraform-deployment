echo "Terraform apply for NSE sandbox"

terraform apply -auto-approve \
                -target=module.obi_one \
                -target=module.obi_generative_gui \
                -target=aws_ecs_service.obi_one_ecs_service \
                -target=aws_ecs_service.obi_generative_gui_ecs_service \
                -var-file=sandbox-nse.tfvars
