resource "aws_instance" "compute" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  count                       = var.create_compute_instances ? var.num_compute_instances : 0
  subnet_id                   = aws_subnet.compute.id
  key_name                    = aws_key_pair.dries-mac-bbp.id
  vpc_security_group_ids      = [] # FIXME define this
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
    Name = "sbo-poc-compute"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

# EFS storage to start with
resource "aws_efs_file_system" "compute_efs" {
  #ts:skip=AC_AWS_0097
  creation_token         = "sbo-poc-compute-efs"
  availability_zone_name = "${var.aws_region}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name = "sbp-poc-compute"
  }
}

resource "aws_efs_backup_policy" "compute_backup_policy" {
  file_system_id = aws_efs_file_system.compute_efs.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_security_group" "compute_efs" {
  name   = "compute_efs"
  vpc_id = aws_vpc.sbo_poc.id

  description = "SBO compute EFS filesystem"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [aws_vpc.sbo_poc.cidr_block]
    description = "allow ingress within vpc"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [aws_vpc.sbo_poc.cidr_block]
    description = "allow egress within vpc"
  }
}

