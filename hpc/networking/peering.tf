resource "aws_route" "existing_to_peer" {
  count                     = length(var.peering_route_tables)
  route_table_id            = var.peering_route_tables[count.index]
  destination_cidr_block    = "172.32.0.0/16"
  vpc_peering_connection_id = var.vpc_peering_connection_id
}

resource "aws_route" "peer_to_existing" {
  count                     = length(var.existing_route_targets)
  route_table_id            = aws_route_table.compute[count.index].id
  destination_cidr_block    = var.existing_route_targets[count.index]
  vpc_peering_connection_id = var.vpc_peering_connection_id
}
