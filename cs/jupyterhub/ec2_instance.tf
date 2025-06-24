locals {
  ec2_name = basename(abspath(var.jupyterhub_base_path))
}

data "aws_ami" "jupyterhub_os" {
  most_recent = false
  filter {
    name   = "name"
    values = ["${var.jupyterhub_ec2_operating_system}"]
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
  ami                         = data.aws_ami.jupyterhub_os.id
  instance_type               = var.jupyterhub_ec2_type
  subnet_id                   = var.jupyterhub_private_subnet
  key_name                    = var.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.jupyterhub_sg.id]
  associate_public_ip_address = false

  user_data_replace_on_change = true
  monitoring                  = true

  user_data = templatefile("${path.module}/${var.jupyterhub_ec2_config_template}",
    { ADMIN_USER       = "obi-administrator",
      ADMIN_PASS       = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["JUPYTER_ADMIN_PASS"],
      BASE_PATH        = var.jupyterhub_base_path,
      CS_SSH_KEY       = var.aws_coreservices_ssh_key_id,
      HOMEDIRS_EFS     = aws_efs_file_system.jupyterhub_homedirs.dns_name,
      HOMEDIRS_PATH    = "/home",
      JUPYTERHUB_PORT  = var.jupyterhub_port,
      KC_CLIENT_ID     = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["KC_CLIENT_ID"],
      KC_CLIENT_SECRET = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["KC_CLIENT_SECRET"],
      KC_REALM         = "SBO",
      PRIMARY_DOMAIN   = var.primary_domain,
    }
  )

  tags = {
    Name        = "${local.ec2_name}_svc"
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
