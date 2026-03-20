resource "aws_sesv2_configuration_set" "main" {
  configuration_set_name = "main-ses-config"

  sending_options {
    sending_enabled = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "sns_topic" {
  configuration_set_name = aws_sesv2_configuration_set.main.configuration_set_name
  event_destination_name = "sns_topic"

  event_destination {
    enabled = true
    # Other options:
    # "OPEN": but then AWS will inject a tracking 1x1 pixel in the html part of the multipart emails
    # "CLICK": but then AWS will replace all links with awstrack.me links in the html part of the multipart emails
    matching_event_types = ["SEND", "DELIVERY", "BOUNCE", "COMPLAINT", "REJECT", "RENDERING_FAILURE", "DELIVERY_DELAY", "SUBSCRIPTION"]

    sns_destination {
      topic_arn = aws_sns_topic.topic.arn
    }
  }
}
