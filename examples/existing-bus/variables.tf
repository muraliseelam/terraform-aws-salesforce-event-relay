variable "aws_region" {
  description = "AWS region containing the active Salesforce partner event source and bus."
  type        = string
  default     = "us-east-1"
}

variable "partner_event_source_name_prefix" {
  description = "Full name or unique prefix of the active Salesforce partner event source."
  type        = string
}
