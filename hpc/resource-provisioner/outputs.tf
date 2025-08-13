output "api_url" {
  description = "The URL of the API Gateway endpoint"
  value       = "${aws_api_gateway_stage.hpc_resource_provisioner_api_stage.invoke_url}/hpc-provisioner"
}
