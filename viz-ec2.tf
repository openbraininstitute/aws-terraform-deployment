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
  image_id               = data.aws_ami.amazonlinux.id
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

data "template_file" "viz_ec2_ecs_user_data" {
  template = file("viz_ec2_ecs_user_data.sh")

  vars = {
    ecs_cluster_name = aws_ecs_cluster.viz_ecs_cluster.name
  }
}

resource "aws_security_group" "viz_ec2_sg" {
  name        = "viz_ec2_sg"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for Brayns service"

  tags = {
    Name        = "viz_brayns_secgroup"
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "viz_brayns_allow_port_5000" {
  security_group_id = aws_security_group.viz_ec2_sg.id

  ip_protocol = "tcp"
  from_port   = 5000
  to_port     = 5000
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
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
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
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
  max_size            = 10
  min_size            = 0
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

  protect_from_scale_in = true

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
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_autoscaling_group.arn
    managed_termination_protection = "ENABLED"
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_cluster_capacity_providers" "viz_cluster_cas" {
  cluster_name       = aws_ecs_cluster.viz_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.viz_cas.name]
}
