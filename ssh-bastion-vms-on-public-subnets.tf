resource "aws_instance" "ssh_bastion_a" {
  # TODO create specific security group
  ami                         = data.aws_ami.almalinux.id
  instance_type               = "t3.micro"
  count                       = var.create_ssh_bastion_vm_on_public_a_network ? 1 : 0
  subnet_id                   = aws_subnet.public_a.id
  key_name                    = aws_key_pair.dries-mac-bbp.id
  vpc_security_group_ids      = [aws_security_group.public.id]
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
  zone_id = aws_route53_zone.domain.zone_id
  name    = "ssh_a.shapes-registry.org"
  type    = "A"
  ttl     = 60
  records = [aws_instance.ssh_bastion_a[0].public_ip]
}

resource "aws_route53_record" "ssh_bastion" {
  count   = var.create_ssh_bastion_vm_on_public_a_network ? 1 : 0
  zone_id = aws_route53_zone.domain.zone_id
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
  subnet_id                   = aws_subnet.public_b.id
  key_name                    = aws_key_pair.dries-mac-bbp.id
  vpc_security_group_ids      = [aws_security_group.public.id]
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
  zone_id = aws_route53_zone.domain.zone_id
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
