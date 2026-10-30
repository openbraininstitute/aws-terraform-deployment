variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "internet_access_route_id" {
  description = "Shared private route table (already routes 0.0.0.0/0 via the shared NAT Gateway) - this module's own subnets associate with it rather than creating a new NAT."
  type        = string
}

variable "subnet_cidr_block_a" {
  type    = string
  default = "10.0.40.0/27"
}

variable "subnet_cidr_block_b" {
  type    = string
  default = "10.0.40.32/27"
}

variable "container_uri" {
  description = "Full ECR image URI (including tag) for the AgentCore Runtime container, e.g. 985539765147.dkr.ecr.us-east-1.amazonaws.com/research-agent:v0.1.0"
  type        = string
}

variable "notebook_service_url" {
  description = "notebook-service base URL the Runtime calls directly."
  type        = string
}

# Per-invocation agent budget caps (Strands' own `limits`/intervention
# mechanism) - passed as Runtime env vars rather than baked into the
# image so they can be tuned without a rebuild/redeploy.
variable "agent_max_turns" {
  description = "Max agent loop iterations (model call + any tool execution) per invocation."
  type        = number
  default     = 10
}

variable "agent_max_output_tokens" {
  description = "Max cumulative model output tokens per invocation."
  type        = number
  default     = 8000
}

variable "agent_max_total_tokens" {
  description = "Max cumulative input+output tokens per invocation."
  type        = number
  default     = 50000
}

variable "agent_max_tool_calls" {
  description = "Max total tool calls per invocation."
  type        = number
  default     = 15
}

# Accounting (obp-accounting-sdk) - reports credits for each research
# run under the RESEARCH_AGENT service subtype, once it exists in a
# released accounting-sdk version and a Price entry exists for it.
# Disabled by default so this can be deployed/tested safely before
# that's true.
variable "accounting_base_url" {
  description = "Base URL of the accounting-service API."
  type        = string
  default     = ""
}

variable "accounting_disabled" {
  description = "Set to false only once accounting-sdk's RESEARCH_AGENT subtype is released and a Price entry exists for it."
  type        = bool
  default     = true
}

variable "event_expiry_duration" {
  description = "Days to retain raw AgentCore Memory conversation events."
  type        = number
  default     = 90
}
