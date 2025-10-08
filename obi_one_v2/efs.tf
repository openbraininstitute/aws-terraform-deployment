resource "aws_efs_file_system" "test_perf_efs" {
  performance_mode = "generalPurpose" # generalPurpose or maxIO
  throughput_mode  = "bursting"       # bursting, provisioned, or elastic
  encrypted        = true
  tags             = merge({ Name = "test_perf_efs" }, var.tags)
}

resource "aws_efs_mount_target" "test_perf_efs" {
  file_system_id  = aws_efs_file_system.test_perf.id
  subnet_id       = aws_subnet.obi_one_v2.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow NFS traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
