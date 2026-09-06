provider "aws" {
  region = var.aws_region
}

module "salesforce_event_relay" {
  source = "../.."

  partner_event_source_name_prefix = var.partner_event_source_name_prefix
  associate_partner_event_source   = false
  name                             = "existing-salesforce-relay"

  tags = {
    Environment = "production"
  }
}
