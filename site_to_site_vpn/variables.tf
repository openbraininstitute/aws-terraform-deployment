variable "vpc_id" {
  description = "The ID of the VPC to use for this VPN connection"
  type        = string
  sensitive   = false
}

variable "aws_bgp_asn" {
  description = "The BGP ASN number on the AWS side"
  type        = number
  sensitive   = false
}

variable "azure_bgp_asn" {
  description = "The BGP ASN number on the Azure side"
  type        = number
  sensitive   = false
}

variable "azure_vpn_gateway_tunnel1_ip_address" {
  description = "The IP address of the tunnel interface on the Azure VPN Gateway"
  type        = string
  sensitive   = false
}

variable "azure_vpn_gateway_preshared_key" {
  description = "The preshared key for the Azure VPN Gateway"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
  sensitive   = false
}
