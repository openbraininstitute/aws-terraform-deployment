# AMI for AlmaLinux 9
data "aws_ami" "almalinux" {
  most_recent = false

  filter {
    name   = "name"
    values = ["AlmaLinux OS*9.4.20240805*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["764336703387"] # AlmaLinux
}

# AMI for latest Amazon Linux with ECS installed
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

