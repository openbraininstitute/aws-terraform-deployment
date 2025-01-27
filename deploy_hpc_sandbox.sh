
pushd aws-terraform-deployment
export TF_VAR_nise_dockerhub_password=blah

terraform apply -target="module.hpc.module.vpc" \
                -target="module.hpc.module.security" \
                -target="module.hpc.module.networking" \
                -target="module.hpc.module.resource-provisioner" \
                -target="module.hpc.module.dynamodb" \
                -target="module.hpc.module.efs" \
                -target="module.coreservices_key" \
                -target="aws_instance.ssh_bastion_a" \
                -target="aws_vpc_security_group_ingress_rule.ssh_bastion_hosts_allow_ssh_external" \
                -target="aws_vpc_security_group_egress_rule.ssh_bastion_hosts_allow_everything_outgoing" \
                -target="aws_subnet.bbp_workflow_svc" \
                -target="aws_route_table_association.bbp_workflow_svc" \
                -target="aws_security_group.bbp_workflow_svc" \
                -target="aws_apigatewayv2_api.this" \
                -target="module.bbp_workflow_svc" \
                -var "create_ssh_bastion_vm_on_public_a_network=true" \
                -var-file=sandbox-hpc.tfvars
popd
