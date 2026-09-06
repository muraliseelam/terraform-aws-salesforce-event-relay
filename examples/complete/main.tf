provider "aws" {
  region = var.aws_region
}

module "salesforce_event_relay" {
  source = "../.."

  partner_event_source_name_prefix = var.partner_event_source_name_prefix
  name                             = "customer-cdc"

  event_pattern = jsonencode({
    "detail-type" = [
      "AccountChangeEvent",
      "ContactChangeEvent"
    ]
    detail = {
      payload = {
        ChangeEventHeader = {
          changeType = ["CREATE", "UPDATE", "DELETE", "UNDELETE"]
        }
      }
    }
  })

  enable_archive          = true
  archive_retention_days  = 90
  enable_schema_discovery = true
  alarm_actions           = var.alarm_actions

  tags = {
    Application = "salesforce-integration"
    Environment = var.environment
    Owner       = "platform-engineering"
  }
}
