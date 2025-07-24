resource "aws_subnet" "bluenaas_ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.18.0/27"
  tags = {
    Name = "bluenaas_ecs_a"
  }
}

resource "aws_subnet" "bluenaas_ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.18.32/27"
  tags = {
    Name = "bluenaas_ecs_b"
  }
}

# give access to the internet so dockerhub can be reached
resource "aws_route_table_association" "bluenaas_ecs_a_docker_access" {
  subnet_id      = aws_subnet.bluenaas_ecs_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "bluenaas_ecs_b_docker_access" {
  subnet_id      = aws_subnet.bluenaas_ecs_b.id
  route_table_id = var.internet_access_route_id
}
