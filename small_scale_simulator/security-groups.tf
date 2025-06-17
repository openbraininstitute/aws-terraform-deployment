resource "aws_security_group" "storage" {
  name_prefix = "small-scale-simulator-efs-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "small-scale-simulator-efs-sg"
  }
}

resource "aws_security_group" "redis" {
  name_prefix = "small-scale-simulator-redis-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.api.id, aws_security_group.worker.id]
  }

  # TODO : check if this is needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "small-scale-simulator-redis-sg"
  }
}

resource "aws_security_group" "api" {
  name_prefix = "small-scale-simulator-api-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    # security_groups = [aws_security_group.alb.id]
  }

  # TODO : check if this is needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "small-scale-simulator-api-sg"
  }
}

resource "aws_security_group" "worker" {
  name_prefix = "small-scale-simulator-worker-"
  vpc_id      = aws_vpc.main.id

  # TODO : check if this is needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "small-scale-simulator-worker-sg"
  }
}
