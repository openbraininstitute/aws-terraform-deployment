# Based on:
# https://aws.amazon.com/blogs/modernizing-with-aws/designing-private-network-connectivity-aws-azure/
# https://techcommunity.microsoft.com/blog/startupsatmicrosoftblog/how-to-easily-set-up-a-vpn-between-azure-and-aws-using-managed-services-updated-/4278966

# For now connection between Azure VirtualHub (part of VirtualWAN) and a single AWS VPC.
# Next step (once also AWS deployments have different network ranges): change this into a transit gateway at the AWS side,
# in some shared network AWS account, if that's still needed by that time.

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id          = var.vpc_id
  amazon_side_asn = var.aws_bgp_asn
}

# Create a Customer Gateway for the Azure Virtual Hub VPN Gateway
resource "aws_customer_gateway" "azure_hub_gw" {
  bgp_asn    = var.azure_bgp_asn
  ip_address = var.azure_vpn_gateway_tunnel1_ip_address
  type       = "ipsec.1"

  tags = {
    Name = "CGW-to-Azure-Hub"
  }
}

# Create a VPN Connection to the Azure Virtual Hub
resource "aws_vpn_connection" "to_azure_hub" {
  vpn_gateway_id          = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id     = aws_customer_gateway.azure_hub_gw.id
  type                    = aws_customer_gateway.azure_hub_gw.type
  static_routes_only      = false
  outside_ip_address_type = "PublicIpv4"

  tunnel1_preshared_key = var.azure_vpn_gateway_preshared_key
  tunnel2_preshared_key = var.azure_vpn_gateway_preshared_key

  tags = {
    Name = "VPN-to-Azure-Hub"
  }
}