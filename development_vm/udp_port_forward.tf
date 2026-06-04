# Only enabled if public_nlb_arn is set, to forward UDP traffic.

resource "aws_lb_target_group" "udp_forward_to_vm" {
  count = var.public_nlb_arn == null ? 0 : 1

  name        = replace("${var.vm_name}-udp", "_", "-")
  port        = var.udp_port_forward_from_public_nlb
  protocol    = "UDP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  # NLB target groups require health checks.
  # Health checks cannot use UDP, so use TCP/HTTP/HTTPS.
  # This assumes the VM has something reachable on TCP/8080 for health checks.
  health_check {
    protocol            = "TCP"
    port                = "8080"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group_attachment" "vm" {
  count = var.public_nlb_arn == null ? 0 : 1

  target_group_arn = aws_lb_target_group.udp_forward_to_vm[0].arn
  target_id        = aws_instance.instance.id
  port             = var.udp_port_forward_from_public_nlb
}


resource "aws_lb_listener" "udp_listener" {
  count = var.public_nlb_arn == null ? 0 : 1

  load_balancer_arn = var.public_nlb_arn
  port              = var.udp_port_forward_from_public_nlb
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.udp_forward_to_vm[0].arn
  }
}


# empty, without rules
# To be edited manually by Juanjo so he can add/update his own ip address when necessary
resource "aws_security_group" "udp_security_group" {
  count = var.public_nlb_arn == null ? 0 : 1

  name        = "${var.vm_name}-udp"
  description = "Allow certain UDP traffic to VM"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.vm_name}-udp"
  }
}
