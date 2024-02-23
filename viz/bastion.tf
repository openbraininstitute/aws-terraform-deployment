resource "aws_key_pair" "admin" {
  key_name   = "admin"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAs3rWWl4AitIQvsx89Z9RH1ktvIVQtCi0E8e7MVRJIcAAvO3A+fIrDP+2lr2j413ycPQDQfSjRlI4q/QllzBWO9M/WRFxOhoyNiQHQRoRMin978eBwev3V8eOgNinvQvNrjHX2JMec0lUiKg6Ik/KLWkbuf7Oij9S5oHyUNl3yTIj2CtII1q3TW95jHmfo6ZMqyyOWQM79NkeC9dMv8jVpw+SwCCWQ3+M0XkDKtAw9xmjV0F0CvrSWcDXwDqQMJm+xn2uzvueRDmgExTHaAzp2hFHGvk+1SWXQLqCG9nMr1zrXIA+mOBc3kmPqXh06HHzvQf5fDePOMnJ7yzJagZoA4I/rQO70gX33JaOgqr/SRgO6mUqgWUfDzRlCLKCSzFHqhFmHM6Nhgm5Nx/fzpNaaZzzqUhecIhmgyr7nZ/hrh0R/EpgqkIOkq1MQ+wRemzvNkAVdbyEZMF9D2QodzU6bVxkquDLyEronL2w3csgCRee8g8Wa8AKvmIQH19M830= podhajsk@ub"
}

#tfsec:ignore:aws-ec2-enable-at-rest-encryption tfsec:ignore:aws-ec2-enforce-http-token-imds
resource "aws_instance" "ec2_viz_bastion" {
  count                  = local.sandbox_resource_count
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  ami                    = "ami-0e731c8a588258d0d"
  subnet_id              = aws_subnet.viz_public_a[0].id
  key_name               = aws_key_pair.admin.key_name
  instance_type          = "t2.micro"
  tags = {
    "Name" = "bastion"
  }
}

resource "aws_security_group" "bastion_sg" {
  count       = local.sandbox_resource_count
  name        = "viz_bastion_sg"
  vpc_id      = data.aws_vpc.selected.id
  description = "Sec group for Brayns service"

  tags = {
    Name        = "viz_bastion_secgroup"
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_sg_allow_ssh" {
  count             = local.sandbox_resource_count
  security_group_id = aws_security_group.bastion_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow port 22 ssh"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_egress_rule" "viz_bastion_allow_egress" {
  count             = local.sandbox_resource_count
  security_group_id = aws_security_group.bastion_sg[0].id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow everything"
  tags = {
    SBO_Billing = "viz"
  }
}
