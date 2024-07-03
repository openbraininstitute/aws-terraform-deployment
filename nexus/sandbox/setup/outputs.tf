output "vpc_id" {
  value = aws_vpc.sandbox.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.sandbox.id
}

output "public_load_balancer_dns_name" {
  value = aws_lb.alb.dns_name
}

output "public_lb_listener_http_arn" {
  value = aws_lb_listener.http.arn
}

output "domain_zone_id" {
  value = aws_route53_zone.domain.id
}
