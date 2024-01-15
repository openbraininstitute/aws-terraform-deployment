resource "aws_appconfig_application" "nexus-delta" {
  name        = "nexus_delta"
  description = "Nexus Delta AppConfig"
}

resource "aws_appconfig_environment" "nexus-delta" {
  name           = "poc"
  description    = "poc test"
  application_id = aws_appconfig_application.nexus-delta.id
}

resource "aws_appconfig_configuration_profile" "nexus-delta" {
  name           = "your_configuration_profile_name"
  application_id = aws_appconfig_application.nexus-delta.id
  location_uri   = "hosted"
}

resource "aws_appconfig_deployment" "nexus-delta" {
  description              = "test deployment"
  application_id           = aws_appconfig_application.nexus-delta.id
  environment_id           = aws_appconfig_environment.nexus-delta.id
  configuration_profile_id = aws_appconfig_configuration_profile.nexus-delta.id
  configuration_version    = "1"
  deployment_strategy_id   = "AppConfig.AllAtOnce"
}