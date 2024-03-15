data "aws_ami" "amazon_linux_2_ecs" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}


resource "aws_iam_role" "ec2_instance_role" {
  name = "viz_EC2_InstanceRole"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Action" = "sts:AssumeRole"
        "Effect" = "Allow"
        "Sid"    = ""
        "Principal" = {
          "Service" = ["ec2.amazonaws.com", "ecs.amazonaws.com"]
        }
      },
    ]
  })
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_instance_role_profile" {
  name = "viz_EC2_InstanceRoleProfile"
  role = aws_iam_role.ec2_instance_role.id
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_launch_template" "ecs_launch_template" {
  name                   = "viz_EC2_LaunchTemplate"
  image_id               = data.aws_ami.amazon_linux_2_ecs.id
  instance_type          = "t3.medium"
  user_data              = base64encode(data.template_file.viz_ec2_ecs_user_data.rendered)
  vpc_security_group_ids = [aws_security_group.viz_ec2_sg.id]

  metadata_options {
    http_tokens = "required"
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
  }

  monitoring {
    enabled = true
  }

  tags = {
    SBO_Billing = "viz"
  }
}

locals {
  viz_user_data = var.viz_enable_sandbox ? "viz_ec2_ecs_user_data.sh" : "viz/viz_ec2_ecs_user_data.sh"
}

data "template_file" "viz_ec2_ecs_user_data" {
  template = file(local.viz_user_data)

  vars = {
    ecs_cluster_name = aws_ecs_cluster.viz_ecs_cluster.name
  }
}

resource "aws_security_group" "viz_ec2_sg" {
  name        = "viz_ec2_sg"
  vpc_id      = data.aws_vpc.selected.id
  description = "Sec group for Brayns service"

  tags = {
    Name        = "viz_brayns_secgroup"
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "viz_brayns_allow_port_22" {
  security_group_id = aws_security_group.viz_ec2_sg.id

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
  description = "Allow port 22 ssh"

  tags = {
    SBO_Billing = "viz"
  }
}


resource "aws_vpc_security_group_ingress_rule" "viz_brayns_allow_port_5000" {
  security_group_id = aws_security_group.viz_ec2_sg.id

  ip_protocol = "tcp"
  from_port   = 5000
  to_port     = 5000
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
  description = "Allow port 5000 http / websocket"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "viz_brayns_allow_port_8000" {
  security_group_id = aws_security_group.viz_ec2_sg.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
  description = "Allow port 8000 http / websocket"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_egress_rule" "viz_brayns_allow_outgoing" {
  security_group_id = aws_security_group.viz_ec2_sg.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow everything"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name                = "viz_asg"
  max_size            = 2
  min_size            = 0
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.viz.id]
  health_check_type   = "EC2"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = true
  }

  protect_from_scale_in = false

  tag {
    key                 = "Name"
    value               = "viz_asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "SBO_Billing"
    value               = "viz"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "viz_cas" {
  name = "viz_ECS_CapacityProvider"

  auto_scaling_group_provider {
    managed_scaling {
      status                 = "ENABLED"
      instance_warmup_period = 10
    }
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_autoscaling_group.arn
    managed_termination_protection = "DISABLED"
    managed_draining               = "DISABLED"
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_cluster_capacity_providers" "viz_cluster_cas" {
  cluster_name       = aws_ecs_cluster.viz_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.viz_cas.name]
}
