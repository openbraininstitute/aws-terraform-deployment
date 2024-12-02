# TODO do we really need this? Should we have one for everyone? In that case this should be in its own module
resource "aws_key_pair" "heeren_ec2_login" {
  key_name   = "heeren_ec2_login"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZRze6uqUFMmBjIDh4bgPugKl8w75Zpxh2SSHbZDyXzAx3Ssa89IK14I4OkZJ9pp8nOCvOwV3qQY1lFUDDdkLfNmvXCDynHexGxPQSPOERynFt/tLtkTjPvgtmCD7OfZ3K0pAD9iKET/CLza6xRZrLeHGAowKcLWKCITL2dI25xuMDTsCqJVW/kp5Pe2W59PD0WPPgcIiD7xOmRmeWdwkCDNKXUbmXDScBDJeQgOwSnjwtU4Pdv93Jl8s/m98CeYdtOCGnNfsrTxd8oGk/CUZtFAXaEz9rI9dfbywNuW5RxmywAlFwnqspcxkY0+/pt+Kpq7io4LkVETJytDBhMxEz heeren@bbd-fsczyl3"

  tags = {
    SBO_Billing = "common"
  }
}

# Can be used for experimenting purposes in the sandbox. This is a node that will accept SSH connections from the outside world to allow us to jump to the compute clusters. It will be associated with the pcluster VPC.
resource "aws_instance" "jumphost" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  count                       = var.create_jumphost ? 1 : 0
  subnet_id                   = var.compute_subnet_public_id
  key_name                    = aws_key_pair.heeren_ec2_login.id
  vpc_security_group_ids      = [var.jumphost_sg_id]
  associate_public_ip_address = true
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
    Name = "sbo-poc-compute-jumphost"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

resource "aws_instance" "compute" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.compute_instance_type
  #instance_type               = "hpc7g.16xlarge"
  count                       = var.create_compute_instances ? var.num_compute_instances : 0
  subnet_id                   = var.compute_subnet_id
  key_name                    = aws_key_pair.heeren_ec2_login.id
  vpc_security_group_ids      = [var.compute_hpc_sg_id]
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

resource "aws_ec2_instance_state" "compute" {
  instance_id = aws_instance.compute[count.index].id
  # TODO Reset to "stopped"
  state = "stopped"
  count = var.create_compute_instances ? var.num_compute_instances : 0
}
