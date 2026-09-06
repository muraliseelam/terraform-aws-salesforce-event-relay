variable "aws_region" {
  description = "AWS region containing the Salesforce partner event source."
  type        = string
  default     = "us-east-1"
}

variable "partner_event_source_name_prefix" {
  description = "Full name or unique prefix of the Salesforce partner event source."
  type        = string
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "production"
}

variable "alarm_actions" {
  description = "CloudWatch alarm action ARNs."
  type        = list(string)
  default     = []
}
