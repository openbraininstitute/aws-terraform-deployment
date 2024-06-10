output "jumphost_public_ip" {
  value = one(aws_instance.jumphost[*].public_ip)
}
