data "aws_iam_policy_document" "ec2" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

resource "aws_iam_role" "ec2" {
  assume_role_policy = data.aws_iam_policy_document.ec2.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
  tags = var.tags
}

resource "aws_iam_instance_profile" "ec2" {
  role = aws_iam_role.ec2.id
  tags = var.tags
}

data "template_file" "ec2_user_data" {
  template = file("${path.module}/ec2-user-data.sh")
  vars = {
    ecs_cluster_name   = local.cluster_name
    ecs_container_tags = join(",", [for k, v in var.tags : "\"${k}\": \"${v}\""])
  }
}

resource "aws_launch_template" "this" {
  name          = var.svc_name
  image_id      = var.ec2_image_id
  instance_type = var.ec2_instance_type
  user_data     = base64encode(data.template_file.ec2_user_data.rendered)
  iam_instance_profile { arn = aws_iam_instance_profile.ec2.arn }
  monitoring { enabled = true }
  metadata_options { http_tokens = "required" }
  tags = var.tags
}

resource "aws_autoscaling_group" "this" {
  name                      = var.svc_name
  min_size                  = 0
  max_size                  = 1
  health_check_grace_period = 0
  default_cooldown          = 120
  health_check_type         = "EC2"
  protect_from_scale_in     = false
  vpc_zone_identifier       = [var.ec2_subnet_id]
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = local.cluster_name
    propagate_at_launch = true
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
