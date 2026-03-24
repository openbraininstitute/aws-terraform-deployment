
# EC2 instance template with user data
resource "aws_launch_template" "launch_template" {
  name          = var.vm_name
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_setup.sh", {
    user_groups = jsonencode(var.user_groups)
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.sg.id]
    subnet_id                   = aws_subnet.subnet.id
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
      Name = var.vm_name
    }
  }
}

# EC2 instance
resource "aws_instance" "instance" {
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  # user_data_replace_on_change = false

  # lifecycle {
  #   ignore_changes = [user_data]
  # }

  tags = {
    Name = var.vm_name
  }
}

resource "aws_ec2_instance_state" "instance_state" {
  instance_id = aws_instance.instance.id
  state       = "stopped"

  lifecycle {
    ignore_changes = [state]
  }
}

# IAM instance profile
resource "aws_iam_instance_profile" "instance_profile" {
  role = aws_iam_role.launch_template.name
}

# Security group
resource "aws_security_group" "sg" {
  name        = "${var.vm_name}-security-group"
  description = "Security group for ${var.vm_name}"
  vpc_id      = var.vpc_id

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress traffic"
  }

  # Allow egress to VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "Allow all outbound traffic within VPC"
  }

  # Allow ingress from VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "Allow any incoming port"
  }
}
