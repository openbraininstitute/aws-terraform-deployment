
resource "aws_launch_template" "nexus_storage_ec2_launch_template" {
  name                   = "nexus_storage_ec2_launch_template"
  image_id               = var.amazon_linux_ecs_ami_id
  instance_type          = "t2.micro"
  user_data              = base64encode(templatefile("${path.module}/init_storage_instance.sh", { ecs_cluster_name = var.ecs_cluster_name, s3_bucket_name = var.s3_bucket_name }))
  update_default_version = true

  vpc_security_group_ids = [var.subnet_security_group_id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.nexus_storage_ec2_instance_role_profile.arn
  }

  metadata_options {
    http_tokens = "required"
  }

  monitoring {
    enabled = true
  }
  tags = { SBO_Billing = "nexus_storage" }
}

resource "aws_ecs_capacity_provider" "nexus_storage_cas" {
  name = "NexusStorage_ECS_CapacityProvider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.nexus_storage_ecs_autoscaling_group.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status = "ENABLED"
    }
  }

  tags = { SBO_Billing = "nexus_storage" }
}

resource "aws_ecs_cluster_capacity_providers" "cas" {
  cluster_name       = var.ecs_cluster_name
  capacity_providers = [aws_ecs_capacity_provider.nexus_storage_cas.name]
}

resource "aws_autoscaling_group" "nexus_storage_ecs_autoscaling_group" {
  name                  = "NexusStorage_ASG"
  max_size              = 1
  min_size              = 1
  vpc_zone_identifier   = [var.subnet_id]
  health_check_type     = "EC2"
  protect_from_scale_in = true

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
    id      = aws_launch_template.nexus_storage_ec2_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "NexusStorage_ASG"
    propagate_at_launch = true
  }

  tag {
    key                 = "SBO_Billing"
    value               = "nexus_storage"
    propagate_at_launch = true
  }
}
