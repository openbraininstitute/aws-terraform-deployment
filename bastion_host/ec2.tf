
# EC2 instance template with user data
resource "aws_launch_template" "ssm_instance" {
  name          = "ssm-instance-template"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_setup.sh", {
    user_groups = jsonencode(local.user_groups)
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ssm_sg.id]
    subnet_id                   = aws_subnet.bastion.id
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.instance_volume_size
      volume_type = "gp3"
      encrypted   = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "SSM-Bastion-Host"
    }
  }
}

# EC2 instance
resource "aws_instance" "bastion" {
  launch_template {
    id      = aws_launch_template.ssm_instance.id
    version = "$Latest"
  }

  user_data_replace_on_change = false

  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = "SSM-Bastion-Host"
  }
}

# IAM instance profile
resource "aws_iam_instance_profile" "ssm_profile" {
  role = aws_iam_role.ssm_instance_role.name
}

# Security group
resource "aws_security_group" "ssm_sg" {
  name        = "ssm-security-group"
  description = "Security group for SSM managed instances"
  vpc_id      = var.vpc_id

  # Allow HTTPS egress for SSM communication
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound traffic for SSM"
  }

}
