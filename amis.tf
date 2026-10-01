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
    values = ["al2023-ami-ecs-hvm-*-kernel-6.1-x86_64"]
  }

  owners = ["amazon"]
}

# AMI for latest Amazon Linux (arm64/Graviton) with ECS installed
data "aws_ami" "amazon_linux_2_ecs_arm64" {
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
    values = ["al2023-ami-ecs-hvm-*-kernel-6.1-arm64"]
  }

  owners = ["amazon"]
}
