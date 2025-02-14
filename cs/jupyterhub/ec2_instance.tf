# AMI for Ubuntu 24.04 LTS
data "aws_ami" "ubuntu2404" {
  most_recent = false
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250115"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "jupyterhub_server" {
  ami                         = data.aws_ami.ubuntu2404.id
  instance_type               = "t3.medium"
  subnet_id                   = var.jupyterhub_private_subnet
  key_name                    = var.aws_coreservices_ssh_key_id
  vpc_security_group_ids      = [aws_security_group.jupyterhub_sg.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true
  monitoring                  = true

  user_data = <<EOF
#!/bin/bash
sudo apt update
sudo apt install nfs-common -y
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.jupyterhub_homedirs.dns_name}:/ /home
EOF

  tags = {
    Name        = "jupyterhub_svc"
    SBO_Billing = "jupyterhub_svc"
  }

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}
