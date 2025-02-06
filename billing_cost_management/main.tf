# Enable AWS Cost Optimization Hub, including all the accounts of the organization
resource "aws_costoptimizationhub_enrollment_status" "aws_cost_opt_hub" {
  count = var.is_production ? 1 : 0

  include_member_accounts = true
}
