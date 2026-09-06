data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_cloudwatch_event_source" "salesforce" {
  name_prefix = var.partner_event_source_name_prefix
}

locals {
  event_bus_name = data.aws_cloudwatch_event_source.salesforce.name
  event_bus_arn  = var.associate_partner_event_source ? aws_cloudwatch_event_bus.salesforce[0].arn : "arn:${data.aws_partition.current.partition}:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:event-bus/${local.event_bus_name}"
  event_pattern = coalesce(
    var.event_pattern,
    jsonencode({
      source = [data.aws_cloudwatch_event_source.salesforce.name]
    })
  )
  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "salesforce-event-relay"
    },
    var.tags
  )
}

resource "aws_cloudwatch_event_bus" "salesforce" {
  count = var.associate_partner_event_source ? 1 : 0

  name              = data.aws_cloudwatch_event_source.salesforce.name
  event_source_name = data.aws_cloudwatch_event_source.salesforce.name
  description       = "Salesforce Event Relay partner event bus managed by Terraform"
  tags              = local.common_tags

  lifecycle {
    precondition {
      condition     = startswith(data.aws_cloudwatch_event_source.salesforce.name, "aws.partner/salesforce.com/")
      error_message = "The discovered partner event source is not owned by Salesforce."
    }
  }
}

resource "aws_sqs_queue" "processing_dlq" {
  name                      = "${var.name}-processing-dlq"
  message_retention_seconds = var.processing_dlq_retention_seconds
  sqs_managed_sse_enabled   = true

  tags = merge(local.common_tags, {
    Name    = "${var.name}-processing-dlq"
    Purpose = "Salesforce event consumer failures"
  })
}

resource "aws_sqs_queue" "events" {
  name                       = "${var.name}-events"
  message_retention_seconds  = var.queue_message_retention_seconds
  receive_wait_time_seconds  = var.queue_receive_wait_time_seconds
  visibility_timeout_seconds = var.queue_visibility_timeout_seconds
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.processing_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = merge(local.common_tags, {
    Name    = "${var.name}-events"
    Purpose = "Durable Salesforce events"
  })

  lifecycle {
    precondition {
      condition     = var.processing_dlq_retention_seconds >= var.queue_message_retention_seconds
      error_message = "processing_dlq_retention_seconds must be greater than or equal to queue_message_retention_seconds so failed events do not expire early."
    }
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "processing_dlq" {
  queue_url = aws_sqs_queue.processing_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.events.arn]
  })
}

resource "aws_sqs_queue" "delivery_dlq" {
  name                      = "${var.name}-delivery-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(local.common_tags, {
    Name    = "${var.name}-delivery-dlq"
    Purpose = "EventBridge delivery failures"
  })
}

resource "aws_cloudwatch_event_rule" "salesforce" {
  name           = "${var.name}-route"
  description    = "Routes selected Salesforce Platform Events and CDC events to SQS"
  event_bus_name = local.event_bus_name
  event_pattern  = local.event_pattern
  state          = "ENABLED"
  tags           = local.common_tags

  depends_on = [aws_cloudwatch_event_bus.salesforce]
}

data "aws_iam_policy_document" "events_queue" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.events.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowEventBridgeDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.salesforce.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.events.id
  policy    = data.aws_iam_policy_document.events_queue.json
}

data "aws_iam_policy_document" "delivery_dlq" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.delivery_dlq.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowEventBridgeDeliveryFailures"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.delivery_dlq.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.salesforce.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "delivery_dlq" {
  queue_url = aws_sqs_queue.delivery_dlq.id
  policy    = data.aws_iam_policy_document.delivery_dlq.json
}

data "aws_iam_policy_document" "processing_dlq" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.processing_dlq.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "processing_dlq" {
  queue_url = aws_sqs_queue.processing_dlq.id
  policy    = data.aws_iam_policy_document.processing_dlq.json
}

data "aws_iam_policy_document" "consumer" {
  statement {
    sid    = "ConsumeSalesforceEvents"
    effect = "Allow"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]

    resources = [aws_sqs_queue.events.arn]
  }
}

resource "aws_cloudwatch_event_target" "events" {
  rule           = aws_cloudwatch_event_rule.salesforce.name
  event_bus_name = local.event_bus_name
  target_id      = "${var.name}-sqs"
  arn            = aws_sqs_queue.events.arn

  dead_letter_config {
    arn = aws_sqs_queue.delivery_dlq.arn
  }

  retry_policy {
    maximum_event_age_in_seconds = var.maximum_event_age_in_seconds
    maximum_retry_attempts       = var.maximum_retry_attempts
  }

  depends_on = [
    aws_sqs_queue_policy.events,
    aws_sqs_queue_policy.delivery_dlq
  ]
}

resource "aws_cloudwatch_event_archive" "salesforce" {
  count = var.enable_archive ? 1 : 0

  name             = "${var.name}-archive"
  description      = "Replayable Salesforce Platform Events and CDC events"
  event_source_arn = local.event_bus_arn
  event_pattern    = var.archive_event_pattern
  retention_days   = var.archive_retention_days

  depends_on = [aws_cloudwatch_event_bus.salesforce]
}

resource "aws_schemas_discoverer" "salesforce" {
  count = var.enable_schema_discovery ? 1 : 0

  source_arn  = local.event_bus_arn
  description = "Discovers Salesforce Event Relay event schemas"
  tags        = local.common_tags

  depends_on = [aws_cloudwatch_event_bus.salesforce]
}
