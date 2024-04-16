resource "aws_subnet" "bluenaas_single_cell_ec2" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.32.0/20"

  tags = {
    Name        = "bluenaas-single-cell-ec2"
    SBO_Billing = "bluenaas_single_cell"
  }
}

resource "aws_subnet" "bluenaas_single_cell_ecs" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.48.0/20"

  tags = {
    Name        = "bluenaas-single-cell-ecs"
    SBO_Billing = "bluenaas_single_cell"
  }
}

resource "aws_route_table_association" "bluenaas_single_cell_ec2" {
  subnet_id      = aws_subnet.bluenaas_single_cell_ec2.id
  route_table_id = var.route_table_id
}

resource "aws_route_table_association" "bluenaas_single_cell_ecs" {
  subnet_id      = aws_subnet.bluenaas_single_cell_ecs.id
  route_table_id = var.route_table_id
}
