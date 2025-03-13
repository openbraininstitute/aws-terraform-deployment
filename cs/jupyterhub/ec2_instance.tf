# AMI for Ubuntu 22.04 LTS
data "aws_ami" "ubuntu2204" {
  most_recent = false
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250228"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

data "aws_secretsmanager_secret_version" "jupyterhub_secrets" {
  secret_id = var.jupyterhub_secrets_arn
}

resource "aws_instance" "jupyterhub_server" {
  ami                         = data.aws_ami.ubuntu2204.id
  instance_type               = "c7i.xlarge"
  subnet_id                   = var.jupyterhub_private_subnet
  key_name                    = var.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.jupyterhub_sg.id]
  associate_public_ip_address = false

  user_data_replace_on_change = true
  monitoring                  = true

  user_data = templatefile("${path.module}/jupyterhub_config.sh.tpl",
    { ADMIN_USER       = "obi-administrator",
      ADMIN_PASS       = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["JUPYTER_ADMIN_PASS"],
      BASE_PATH        = var.jupyterhub_base_path,
      HOMEDIRS_EFS     = aws_efs_file_system.jupyterhub_homedirs.dns_name,
      HOMEDIRS_PATH    = "/home",
      KC_CLIENT_ID     = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["KC_CLIENT_ID"],
      KC_CLIENT_SECRET = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["KC_CLIENT_SECRET"],
      KC_REALM         = "SBO",
      PRIMARY_DOMAIN   = var.primary_domain,
    }
  )

  tags = {
    Name        = "jupyterhub_svc"
    SBO_Billing = "jupyterhub_svc"
  }

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}
