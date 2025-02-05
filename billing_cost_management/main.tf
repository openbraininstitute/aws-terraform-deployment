# Enable AWS Cost Optimization Hub, including all the accounts of the organization
resource "aws_costoptimizationhub_enrollment_status" "aws_cost_opt_hub" {
  include_member_accounts = true

  tags = {
    SBO_Billing = "cost_optimization"
  }
}

