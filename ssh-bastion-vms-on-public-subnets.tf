resource "aws_instance" "ssh_bastion" {
  # TODO create specific security group
  ami                         = data.aws_ami.almalinux.id
  instance_type               = "t3.medium"
  count                       = var.create_ssh_bastion_vm_on_public_a_network ? 1 : 0
  subnet_id                   = data.terraform_remote_state.common.outputs.public_a_subnet_id
  key_name                    = module.coreservices_key.key_pair_id
  vpc_security_group_ids      = [aws_security_group.ssh_bastion_hosts.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true
  monitoring                  = true

  user_data = <<EOF
#!/bin/bash
echo "to be replaced with creation of user logins"
  EOF
  tags = {
    Name        = "ssh_bastion"
    SBO_Billing = "common"
  }

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}

resource "aws_route53_record" "ssh_bastion" {
  count   = var.create_ssh_bastion_vm_on_public_a_network ? 1 : 0
  zone_id = data.terraform_remote_state.common.outputs.bastion_domain_zone_id
  name    = "ssh.${data.terraform_remote_state.common.outputs.bastion_domain}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.ssh_bastion[0].public_ip]
}

output "admin_vm_on_public_a_network_name" {
  value = length(aws_instance.ssh_bastion) > 0 ? aws_instance.ssh_bastion[0].public_dns : null
}

output "admin_vm_on_public_a_network_ip" {
  value = length(aws_instance.ssh_bastion) > 0 ? aws_instance.ssh_bastion[0].public_ip : null
}

output "admin_vm_on_public_a_dns_cname" {
  value = length(aws_instance.ssh_bastion) > 0 ? aws_route53_record.ssh_bastion[0].name : null
}

# Security group for the public networks
resource "aws_security_group" "ssh_bastion_hosts" {
  name        = "ssh bastion hosts"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for the ssh_bastion_hosts"

  tags = {
    Name        = "ssh_bastion_hosts"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_http_internal" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow HTTP from internal"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = data.terraform_remote_state.common.outputs.vpc_cidr_block

  tags = {
    Name = "ssh_bastion_hosts_allow_http_internal"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_https_internal" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow HTTPS from internal"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = data.terraform_remote_state.common.outputs.vpc_cidr_block

  tags = {
    Name = "ssh_bastion_hosts_allow_https_internal"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_ssh_external" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow SSH from everywhere"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "ssh_bastion_hosts_allow_ssh_external"
  }
}

resource "aws_vpc_security_group_egress_rule" "ssh_bastion_hosts_allow_everything_outgoing" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "ssh_bastion_hosts_allow_everything_outgoing"
  }
}
