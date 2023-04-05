# Created in AWS secret manager
variable "dockerhub_credentials_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:dockerhub-bbpbuildbot-EhUqqE"
  type        = string
  description = "The ARN of the secret containing the credentials for dockerhub to fetch images from private dockerhub repos"
  sensitive   = true
}
