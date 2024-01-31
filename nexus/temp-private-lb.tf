# #### COPIED FROM deployment-common/subnets-private-alb.tf ####

# # AWS load balancers require an IP address on at least
# # 2 subnets in different availability zones.

# # Private subnet in availability zone A for the internal application load balancer
# resource "aws_subnet" "private_alb_a" {
#   vpc_id                  = var.vpc_id
#   cidr_block              = "10.0.2.144/28"
#   availability_zone       = "${var.aws_region}a"
#   map_public_ip_on_launch = false
#   tags = {
#     Name        = "private_alb_a"
#     SBO_Billing = "common"
#   }
# }

# # Private subnet in availability zone B for the internal application load balancer
# resource "aws_subnet" "private_alb_b" {
#   vpc_id                  = var.vpc_id
#   cidr_block              = "10.0.2.160/28"
#   availability_zone       = "${var.aws_region}b"
#   map_public_ip_on_launch = false
#   tags = {
#     Name        = "private_alb_b"
#     SBO_Billing = "common"
#   }
# }

# resource "aws_network_acl" "private_alb" {
#   vpc_id     = var.vpc_id
#   subnet_ids = [aws_subnet.private_alb_a.id, aws_subnet.private_alb_b.id]

#   ingress {
#     protocol   = -1
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = var.vpc_cidr_block
#     from_port  = 0
#     to_port    = 0
#   }
#   egress {
#     protocol   = -1
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }
#   tags = {
#     Name        = "private_alb"
#     SBO_Billing = "common"
#   }
# }

# #### COPIED FROM deployment-common/private-load-balancer.tf ####

# resource "aws_lb" "private_alb" {
#   name               = "sbo-poc-private-alb"
#   internal           = true
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.private_alb.id]
#   subnets            = [aws_subnet.private_alb_a.id, aws_subnet.private_alb_b.id]

#   drop_invalid_header_fields = true

#   tags = {
#     Name        = "sbo-poc-private-alb",
#     SBO_Billing = "common"
#   }
# }

# resource "aws_security_group" "private_alb" {
#   name        = "Private Load balancer"
#   vpc_id      = var.vpc_id
#   description = "Sec group for the private application load balancer"

#   tags = {
#     Name        = "alb_priv_secgroup"
#     SBO_Billing = "common"
#   }
# }

# resource "aws_vpc_security_group_egress_rule" "alb_allow_everything_outgoing" {
#   security_group_id = aws_security_group.private_alb.id
#   description       = "Allow everything outgoing"
#   ip_protocol       = -1
#   cidr_ipv4         = "0.0.0.0/0"

#   tags = {
#     Name = "private_alb_allow_everything_outgoing"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "alb_allow_9999_internal" {
#   security_group_id = aws_security_group.private_alb.id
#   description       = "Allow 9999 from internal"
#   from_port         = 9999
#   to_port           = 9999
#   ip_protocol       = "tcp"
#   cidr_ipv4         = var.vpc_cidr_block

#   tags = {
#     Name = "private_alb_allow_9999_internal"
#   }
# }

# resource "aws_lb_listener" "priv_alb_9999" {
#   load_balancer_arn = aws_lb.private_alb.arn
#   port              = "9999"
#   #ts:skip=AC_AWS_0491
#   protocol = "HTTP" #tfsec:ignore:aws-elb-http-not-used

#   default_action {
#     type = "fixed-response"

#     fixed_response { 
#       content_type = "text/plain"
#       message_body = "Fixed response content: port 9999 listener"
#       status_code  = "200"
#     }
#   }
#   tags = {
#     SBO_Billing = "common"
#   }
#   depends_on = [
#     aws_lb.private_alb
#   ]
# }
