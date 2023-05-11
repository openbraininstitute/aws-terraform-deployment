resource "aws_instance" "compute" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  count                       = var.create_compute_instances ? var.num_compute_instances : 0
  subnet_id                   = aws_subnet.compute.id
  key_name                    = data.terraform_remote_state.common.outputs.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.hpc.id]
  associate_public_ip_address = false
  user_data_replace_on_change = false
  monitoring                  = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "sbo-poc-compute"
    SBO_Billing = "hpc"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

resource "aws_route53_record" "compute" {
  count   = var.create_compute_instances ? var.num_compute_instances : 0
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = "sbo-poc-compute${count.index + 1}.shapes-registry.org"
  type    = "A"
  ttl     = 60
  records = [aws_instance.compute[count.index].private_ip]
}

# EFS storage to start with
resource "aws_efs_file_system" "compute_efs" {
  #ts:skip=AC_AWS_0097
  creation_token         = "sbo-poc-compute-efs"
  availability_zone_name = "${var.aws_region}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "sbo-poc-compute"
    SBO_Billing = "hpc"
  }
}

resource "aws_efs_backup_policy" "compute_backup_policy" {
  file_system_id = aws_efs_file_system.compute_efs.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_security_group" "hpc" {
  name   = "hpc"
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id

  description = "SBO HPC"

  tags = {
    Name        = "sbo-poc-compute"
    SBO_Billing = "hpc"
  }
}
resource "aws_vpc_security_group_ingress_rule" "hpc_allow_ingress_tcp" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 0
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "allow tcp ingress within vpc"

  tags = {
    SBO_Billing = "hpc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "hpc_allow_ingress_udp" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = "udp"
  from_port   = 0
  to_port     = 0
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "allow udp ingress within vpc"

  tags = {
    SBO_Billing = "hpc"
  }
}

resource "aws_vpc_security_group_egress_rule" "hpc_allow_egress_tcp" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 0
  cidr_ipv4   = "0.0.0.0/0"
  description = "allow tcp egress"

  tags = {
    SBO_Billing = "hpc"
  }
}

resource "aws_vpc_security_group_egress_rule" "hpc_allow_egress_udp" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = "udp"
  from_port   = 0
  to_port     = 0
  cidr_ipv4   = "0.0.0.0/0"
  description = "allow udp egress"

  tags = {
    SBO_Billing = "hpc"
  }
}

resource "aws_security_group" "compute_efs" {
  name   = "compute_efs"
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id

  description = "SBO compute EFS filesystem"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow ingress within vpc"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow egress within vpc"
  }

  tags = {
    Name        = "sbo-poc-compute"
    SBO_Billing = "hpc"
  }
}

