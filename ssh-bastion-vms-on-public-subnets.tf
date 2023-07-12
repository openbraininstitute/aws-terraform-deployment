resource "aws_instance" "ssh_bastion_a" {
  # TODO create specific security group
  ami                         = data.aws_ami.almalinux.id
  instance_type               = "t3.micro"
  count                       = var.create_ssh_bastion_vm_on_public_a_network ? 1 : 0
  subnet_id                   = data.terraform_remote_state.common.outputs.public_a_subnet_id
  key_name                    = data.terraform_remote_state.common.outputs.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.ssh_bastion_hosts.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true
  monitoring                  = true

  user_data = <<EOF
#!/bin/bash
echo "to be replaced with creation of user logins"
  EOF
  tags = {
    Name        = "ssh_bastion_a"
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

resource "aws_route53_record" "ssh_bastion_a" {
  count   = var.create_ssh_bastion_vm_on_public_a_network ? 1 : 0
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = "ssh_a.shapes-registry.org"
  type    = "A"
  ttl     = 60
  records = [aws_instance.ssh_bastion_a[0].public_ip]
}

resource "aws_route53_record" "ssh_bastion" {
  count   = var.create_ssh_bastion_vm_on_public_a_network ? 1 : 0
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = "ssh.shapes-registry.org"
  type    = "A"
  ttl     = 60
  records = [aws_instance.ssh_bastion_a[0].public_ip]
}

resource "aws_instance" "ssh_bastion_b" {
  # TODO create specific security group
  ami                         = data.aws_ami.almalinux.id
  instance_type               = "t3.micro"
  count                       = var.create_ssh_bastion_vm_on_public_b_network ? 1 : 0
  subnet_id                   = data.terraform_remote_state.common.outputs.public_b_subnet_id
  key_name                    = data.terraform_remote_state.common.outputs.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.ssh_bastion_hosts.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true
  monitoring                  = true

  user_data = <<EOF
#!/bin/bash
echo "to be replaced with creation of user logins"
  EOF
  tags = {
    Name        = "ssh_bastion_b"
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

resource "aws_route53_record" "ssh_bastion_b" {
  count   = var.create_ssh_bastion_vm_on_public_b_network ? 1 : 0
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = "ssh_b.shapes-registry.org"
  type    = "A"
  ttl     = 60
  records = [aws_instance.ssh_bastion_b[0].public_ip]
}

output "admin_vm_on_public_a_network_name" {
  value = length(aws_instance.ssh_bastion_a) > 0 ? aws_instance.ssh_bastion_a[0].public_dns : null
}

output "admin_vm_on_public_a_network_ip" {
  value = length(aws_instance.ssh_bastion_a) > 0 ? aws_instance.ssh_bastion_a[0].public_ip : null
}

output "admin_vm_on_public_a_dns_cname" {
  value = length(aws_instance.ssh_bastion_a) > 0 ? aws_route53_record.ssh_bastion_a[0].name : null
}

output "admin_vm_on_public_b_network_name" {
  value = length(aws_instance.ssh_bastion_b) > 0 ? aws_instance.ssh_bastion_b[0].public_dns : null
}
output "admin_vm_on_public_b_network_ip" {
  value = length(aws_instance.ssh_bastion_b) > 0 ? aws_instance.ssh_bastion_b[0].public_ip : null
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

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_http_epfl" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow HTTP from EPFL"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "ssh_bastion_hosts_allow_http_epfl"
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

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_https_epfl" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow HTTPS from EPFL"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "ssh_bastion_hosts_allow_https_epfl"
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

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_ssh_epfl" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow SSH from EPFL"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "ssh_bastion_hosts_allow_ssh_epfl"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_bb5_login_nodes" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow SSH from BB5 Login nodes"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.bb5_login_nodes_cidr

  tags = {
    Name = "ssh_bastion_hosts_allow_bb5_login_nodes"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_bbpssh" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow SSH from BBP SSH Bastion host (Jumphost)"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.bbpssh_cidr

  tags = {
    Name = "ssh_bastion_hosts_allow_bbpssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_hosts_allow_ssh_internal" {
  security_group_id = aws_security_group.ssh_bastion_hosts.id
  description       = "Allow SSH from internal"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = data.terraform_remote_state.common.outputs.vpc_cidr_block
  tags = {
    Name = "ssh_bastion_hosts_allow_ssh_internal"
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
