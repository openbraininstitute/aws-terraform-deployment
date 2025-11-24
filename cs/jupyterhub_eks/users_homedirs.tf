resource "aws_efs_file_system" "users_homedirs" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "jupyterhub-svc-efs"
  }
}
