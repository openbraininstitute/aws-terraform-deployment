echo "Terraform apply for NSE sandbox"

terraform apply -auto-approve \
                -target=module.entitycore_svc \
                -target=module.networking \
                -target=aws_db_instance.entitycore \
                -target=aws_ecs_service.entitycore_ecs_service \
                -var-file=sandbox-nse.tfvars
