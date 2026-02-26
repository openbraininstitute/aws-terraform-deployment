# Test VM on the network ranges of JupyterHub, to test the filesystems

data "aws_key_pair" "coreservices" {
  key_name           = var.aws_coreservices_ssh_key_id
  include_public_key = true
}

resource "aws_instance" "filesystem_tests_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_type
  subnet_id                   = var.jupyterhub_eks_private_a_subnet_id
  key_name                    = var.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.filesystems_test_vm_sg.id]
  associate_public_ip_address = false

  user_data_replace_on_change = true
  monitoring                  = true

  user_data = templatefile("${path.module}/user_data.sh.tpl",
    {
      CS_SSH_KEY = "${data.aws_key_pair.coreservices.public_key}",
    }
  )

  tags = {
    Name        = "filesystem_tests_server"
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


data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "filesystems_tests_ec2_vm_role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

# Allow EFS mount
data "aws_iam_policy_document" "efs_client" {
  statement {
    actions = [
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [var.public_data_efs_arn]
  }
}

resource "aws_iam_policy" "efs_client" {
  name   = "ec2-efs-client-demo"
  policy = data.aws_iam_policy_document.efs_client.json
}

resource "aws_iam_role_policy_attachment" "efs_client" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.efs_client.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-efs-demo-profile"
  role = aws_iam_role.ec2.name
}

