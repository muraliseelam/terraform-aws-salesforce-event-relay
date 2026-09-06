variable "partner_event_source_name_prefix" {
  description = "Prefix of the pending or active Salesforce partner event source created by Event Relay. It must identify exactly one source."
  type        = string

  validation {
    condition = (
      startswith(var.partner_event_source_name_prefix, "aws.partner/salesforce.com/") &&
      length(var.partner_event_source_name_prefix) > length("aws.partner/salesforce.com/")
    )
    error_message = "partner_event_source_name_prefix must start with aws.partner/salesforce.com/ and include the Salesforce source identifier."
  }
}

variable "associate_partner_event_source" {
  description = "Whether Terraform should associate the Salesforce partner event source with a new EventBridge partner event bus. Set to false only when the source is already associated."
  type        = bool
  default     = true
}

variable "name" {
  description = "Short name used for rules, queues, archives, dashboards, and alarms."
  type        = string
  default     = "sf-event-relay"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{1,31}$", var.name))
    error_message = "name must be 2-32 characters and contain only letters, numbers, underscores, or hyphens."
  }
}

variable "event_pattern" {
  description = "Optional EventBridge event pattern as a JSON object string. By default, all events from the discovered Salesforce partner source are matched."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.event_pattern == null || can(keys(jsondecode(var.event_pattern)))
    error_message = "event_pattern must be null or a JSON object string."
  }
}

variable "enable_archive" {
  description = "Whether to retain matching Salesforce events in an EventBridge archive for replay."
  type        = bool
  default     = true
}

variable "archive_retention_days" {
  description = "Archive retention in days. Set to null for indefinite retention."
  type        = number
  default     = 30
  nullable    = true

  validation {
    condition     = var.archive_retention_days == null || (var.archive_retention_days >= 1 && var.archive_retention_days <= 3650)
    error_message = "archive_retention_days must be null or between 1 and 3650."
  }
}

variable "archive_event_pattern" {
  description = "Optional EventBridge archive filter as a JSON object string. A null value archives every event on the partner bus."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.archive_event_pattern == null || can(keys(jsondecode(var.archive_event_pattern)))
    error_message = "archive_event_pattern must be null or a JSON object string."
  }
}

variable "enable_schema_discovery" {
  description = "Whether EventBridge Schema Registry should discover schemas from relayed events. Disabled by default to minimize cost and metadata collection."
  type        = bool
  default     = false
}

variable "queue_visibility_timeout_seconds" {
  description = "Visibility timeout for the durable Salesforce event queue."
  type        = number
  default     = 60

  validation {
    condition     = var.queue_visibility_timeout_seconds >= 30 && var.queue_visibility_timeout_seconds <= 43200
    error_message = "queue_visibility_timeout_seconds must be between 30 and 43200."
  }
}

variable "queue_message_retention_seconds" {
  description = "Retention period for unprocessed Salesforce events."
  type        = number
  default     = 345600

  validation {
    condition     = var.queue_message_retention_seconds >= 60 && var.queue_message_retention_seconds <= 1209600
    error_message = "queue_message_retention_seconds must be between 60 and 1209600."
  }
}

variable "queue_receive_wait_time_seconds" {
  description = "Long-polling wait time for consumers of the Salesforce event queue."
  type        = number
  default     = 20

  validation {
    condition     = var.queue_receive_wait_time_seconds >= 0 && var.queue_receive_wait_time_seconds <= 20
    error_message = "queue_receive_wait_time_seconds must be between 0 and 20."
  }
}

variable "processing_dlq_retention_seconds" {
  description = "Retention period for events that downstream consumers fail to process."
  type        = number
  default     = 1209600

  validation {
    condition     = var.processing_dlq_retention_seconds >= 60 && var.processing_dlq_retention_seconds <= 1209600
    error_message = "processing_dlq_retention_seconds must be between 60 and 1209600."
  }
}

variable "max_receive_count" {
  description = "Number of failed consumer receives before SQS moves an event to the processing DLQ."
  type        = number
  default     = 5

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be between 1 and 1000."
  }
}

variable "maximum_event_age_in_seconds" {
  description = "Maximum age of an event that EventBridge retries before sending it to the delivery DLQ."
  type        = number
  default     = 86400

  validation {
    condition     = var.maximum_event_age_in_seconds >= 60 && var.maximum_event_age_in_seconds <= 86400
    error_message = "maximum_event_age_in_seconds must be between 60 and 86400."
  }
}

variable "maximum_retry_attempts" {
  description = "Maximum EventBridge delivery retries before an event is sent to the delivery DLQ."
  type        = number
  default     = 185

  validation {
    condition     = var.maximum_retry_attempts >= 0 && var.maximum_retry_attempts <= 185
    error_message = "maximum_retry_attempts must be between 0 and 185."
  }
}

variable "enable_dashboard" {
  description = "Whether to create a CloudWatch operations dashboard."
  type        = bool
  default     = true
}

variable "enable_alarms" {
  description = "Whether to create CloudWatch alarms for delivery failures, DLQ messages, and stale queue messages."
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other CloudWatch alarm action ARNs notified when an alarm changes to ALARM."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.alarm_actions : can(regex("^arn:[^:]+:[^:]+:", arn))])
    error_message = "Every alarm action must be an ARN."
  }
}

variable "queue_age_alarm_threshold_seconds" {
  description = "Age of the oldest unprocessed event that triggers the queue age alarm."
  type        = number
  default     = 900

  validation {
    condition     = var.queue_age_alarm_threshold_seconds >= 60 && var.queue_age_alarm_threshold_seconds <= 1209600
    error_message = "queue_age_alarm_threshold_seconds must be between 60 and 1209600."
  }
}

variable "tags" {
  description = "Additional tags to apply to supported resources."
  type        = map(string)
  default     = {}
}
