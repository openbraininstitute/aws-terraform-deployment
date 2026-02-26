resource "aws_fsx_lustre_file_system" "lustre" {
  count                       = var.is_lustre_filesystem_enabled ? 1 : 0
  storage_capacity            = 1200
  subnet_ids                  = [aws_subnet.jupyterhub_eks_private_a.id]
  deployment_type             = "PERSISTENT_2"
  per_unit_storage_throughput = 125

  security_group_ids = [aws_security_group.lustre_sg.id]
}

resource "aws_fsx_data_repository_association" "association" {
  count = var.is_lustre_filesystem_enabled ? 1 : 0

  file_system_id       = aws_fsx_lustre_file_system.lustre[0].id
  data_repository_path = "s3://${var.s3_bucket_name}"
  file_system_path     = "/my-bucket"

  batch_import_meta_data_on_create = false
  delete_data_in_filesystem        = true

  s3 {
    auto_export_policy {
      events = []
    }

    auto_import_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }
  }
}

resource "aws_security_group" "lustre_sg" {
  name   = "lustre-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.jupyterhub_eks_private_a_cidr]
  }

  ingress {
    from_port   = 988
    to_port     = 988
    protocol    = "tcp"
    cidr_blocks = [var.jupyterhub_eks_private_b_cidr]
  }

  ingress {
    from_port   = 988
    to_port     = 988
    protocol    = "tcp"
    cidr_blocks = [var.jupyterhub_eks_private_a_cidr]
  }

  ingress {
    from_port   = 1018
    to_port     = 1023
    protocol    = "tcp"
    cidr_blocks = [var.jupyterhub_eks_private_b_cidr]
  }

  tags = {
    Name = "lustre-sg"
  }
}
