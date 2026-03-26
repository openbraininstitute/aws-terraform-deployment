locals {
  ec2_name = basename(abspath(var.jupyterhub_base_path))
}

resource "aws_iam_role" "jupyterhub_ec2_role" {
  name = "${local.ec2_name}_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${local.ec2_name}_ec2_role"
    SBO_Billing = "jupyterhub_svc"
  }
}

resource "aws_iam_role_policy" "jupyterhub_secrets_policy" {
  name = "${local.ec2_name}_secrets_access"
  role = aws_iam_role.jupyterhub_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [var.jupyterhub_secrets_arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jupyterhub_cloudwatch" {
  role       = aws_iam_role.jupyterhub_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "jupyterhub_ssm" {
  role       = aws_iam_role.jupyterhub_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jupyterhub_ec2_profile" {
  name = "${local.ec2_name}_ec2_profile"
  role = aws_iam_role.jupyterhub_ec2_role.name

  tags = {
    Name        = "${local.ec2_name}_ec2_profile"
    SBO_Billing = "jupyterhub_svc"
  }
}

data "aws_key_pair" "coreservices" {
  key_name           = var.aws_coreservices_ssh_key_id
  include_public_key = true
}

data "aws_secretsmanager_secret_version" "jupyterhub_secrets" {
  secret_id = var.jupyterhub_secrets_arn
}

resource "aws_instance" "jupyterhub_server" {
  ami                         = var.jupyterhub_ec2_operating_system
  instance_type               = var.jupyterhub_ec2_type
  subnet_id                   = var.jupyterhub_private_subnet
  key_name                    = var.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.jupyterhub_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.jupyterhub_ec2_profile.name

  user_data_replace_on_change = true
  monitoring                  = true

  user_data = templatefile("${path.module}/${var.jupyterhub_ec2_config_template}",
    { ADMIN_USER        = "obi-administrator",
      ADMIN_PASS        = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["JUPYTER_ADMIN_PASS"],
      BASE_PATH         = var.jupyterhub_base_path,
      CS_SSH_KEY        = "${data.aws_key_pair.coreservices.public_key}",
      HOMEDIRS_EFS      = aws_efs_file_system.jupyterhub_homedirs.dns_name,
      HOMEDIRS_PATH     = "/home",
      JUPYTERHUB_ADMINS = join(" ", var.jupyterhub_admin_users)
      JUPYTERHUB_PORT   = var.jupyterhub_port,
      KC_CLIENT_ID      = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["KC_CLIENT_ID"],
      KC_CLIENT_SECRET  = jsondecode(data.aws_secretsmanager_secret_version.jupyterhub_secrets.secret_string)["KC_CLIENT_SECRET"],
      KC_REALM          = "SBO",
      PRIMARY_DOMAIN    = var.primary_domain,
    }
  )

  tags = {
    Name        = "${local.ec2_name}_svc"
    SBO_Billing = "jupyterhub_svc"
  }

  root_block_device {
    volume_size = var.jupyterhub_ec2_root_volume_size
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}
