locals {
  eventbridge_alarm_metrics = {
    failed-invocations = {
      metric_name = "FailedInvocations"
      description = "EventBridge failed to invoke the Salesforce event queue target."
    }
    events-sent-to-dlq = {
      metric_name = "InvocationsSentToDlq"
      description = "EventBridge exhausted delivery attempts and sent Salesforce events to the delivery DLQ."
    }
    dlq-delivery-failures = {
      metric_name = "InvocationsFailedToBeSentToDlq"
      description = "EventBridge could not send failed Salesforce events to the delivery DLQ."
    }
    retry-attempts = {
      metric_name = "RetryInvocationAttempts"
      description = "EventBridge retried delivery of one or more Salesforce events."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "eventbridge" {
  for_each = var.enable_alarms ? local.eventbridge_alarm_metrics : {}

  alarm_name          = "${var.name}-${each.key}"
  alarm_description   = each.value.description
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = each.value.metric_name
  namespace           = "AWS/Events"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions

  dimensions = {
    EventBusName = local.event_bus_name
    RuleName     = aws_cloudwatch_event_rule.salesforce.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "processing_dlq" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name}-processing-dlq-not-empty"
  alarm_description   = "A downstream consumer failed to process one or more Salesforce events."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.processing_dlq.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name}-oldest-event"
  alarm_description   = "The oldest unprocessed Salesforce event exceeded the configured age threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.queue_age_alarm_threshold_seconds
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.events.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_dashboard" "salesforce" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${var.name}-operations"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Salesforce events routed by EventBridge"
          view   = "timeSeries"
          region = data.aws_region.current.region
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/Events", "Events", "EventSourceName", data.aws_cloudwatch_event_source.salesforce.name, { label = "Events received from Salesforce" }],
            ["AWS/Events", "MatchedEvents", "EventBusName", local.event_bus_name, "RuleName", aws_cloudwatch_event_rule.salesforce.name, { label = "Matched events" }],
            ["AWS/Events", "Invocations", "EventBusName", local.event_bus_name, "RuleName", aws_cloudwatch_event_rule.salesforce.name, { label = "Target invocations" }],
            ["AWS/Events", "FailedInvocations", "EventBusName", local.event_bus_name, "RuleName", aws_cloudwatch_event_rule.salesforce.name, { label = "Failed invocations" }],
            ["AWS/Events", "InvocationsSentToDlq", "EventBusName", local.event_bus_name, "RuleName", aws_cloudwatch_event_rule.salesforce.name, { label = "Sent to delivery DLQ" }],
            ["AWS/Events", "RetryInvocationAttempts", "EventBusName", local.event_bus_name, "RuleName", aws_cloudwatch_event_rule.salesforce.name, { label = "Retry attempts" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Durable event queue"
          view   = "timeSeries"
          region = data.aws_region.current.region
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", aws_sqs_queue.events.name, { label = "Events enqueued" }],
            ["AWS/SQS", "NumberOfMessagesDeleted", "QueueName", aws_sqs_queue.events.name, { label = "Events processed" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.events.name, { label = "Available backlog", stat = "Maximum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Consumer backlog age"
          view   = "timeSeries"
          region = data.aws_region.current.region
          period = 300
          stat   = "Maximum"
          metrics = [
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", aws_sqs_queue.events.name, { label = "Oldest event age (seconds)" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Dead-letter queues"
          view   = "timeSeries"
          region = data.aws_region.current.region
          period = 300
          stat   = "Maximum"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.delivery_dlq.name, { label = "EventBridge delivery failures" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.processing_dlq.name, { label = "Consumer processing failures" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "EventBridge delivery latency"
          view   = "timeSeries"
          region = data.aws_region.current.region
          period = 300
          metrics = [
            ["AWS/Events", "IngestionToInvocationSuccessLatency", "EventBusName", local.event_bus_name, "RuleName", aws_cloudwatch_event_rule.salesforce.name, { label = "p95 ingestion-to-SQS latency", stat = "p95" }]
          ]
        }
      }
    ]
  })
}
