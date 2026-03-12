moved {
  to   = module.launch_system_network.aws_subnet.trusted_a
  from = module.launch_system[0].aws_subnet.trusted_a
}

moved {
  to   = module.launch_system_network.aws_subnet.trusted_b
  from = module.launch_system[0].aws_subnet.trusted_b
}

moved {
  to   = module.launch_system_network.aws_subnet.untrusted_a
  from = module.launch_system[0].aws_subnet.untrusted_a
}

moved {
  to   = module.launch_system_network.aws_subnet.untrusted_b
  from = module.launch_system[0].aws_subnet.untrusted_b
}

moved {
  to   = module.launch_system_network.aws_route_table_association.trusted_a_internet_access
  from = module.launch_system[0].aws_route_table_association.trusted_a_internet_access
}

moved {
  to   = module.launch_system_network.aws_route_table_association.trusted_b_internet_access
  from = module.launch_system[0].aws_route_table_association.trusted_b_internet_access
}

moved {
  to   = module.launch_system_network.aws_route_table_association.untrusted_a_internet_access
  from = module.launch_system[0].aws_route_table_association.untrusted_a_internet_access
}

moved {
  to   = module.launch_system_network.aws_route_table_association.untrusted_b_internet_access
  from = module.launch_system[0].aws_route_table_association.untrusted_b_internet_access
}

