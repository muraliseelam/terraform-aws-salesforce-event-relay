output "partner_event_source" {
  description = "Salesforce partner event source discovered by the module."
  value = {
    arn        = data.aws_cloudwatch_event_source.salesforce.arn
    created_by = data.aws_cloudwatch_event_source.salesforce.created_by
    name       = data.aws_cloudwatch_event_source.salesforce.name
    state      = data.aws_cloudwatch_event_source.salesforce.state
  }
}

output "event_bus" {
  description = "EventBridge partner event bus receiving Salesforce events."
  value = {
    arn  = local.event_bus_arn
    name = local.event_bus_name
  }
}

output "event_rule_arn" {
  description = "ARN of the rule routing Salesforce events to SQS."
  value       = aws_cloudwatch_event_rule.salesforce.arn
}

output "event_queue" {
  description = "Durable queue consumed by downstream Salesforce event processors."
  value = {
    arn  = aws_sqs_queue.events.arn
    name = aws_sqs_queue.events.name
    url  = aws_sqs_queue.events.url
  }
}

output "consumer_iam_policy_json" {
  description = "Least-privilege IAM policy document for a downstream consumer of the Salesforce event queue."
  value       = data.aws_iam_policy_document.consumer.json
}

output "processing_dlq" {
  description = "Queue containing events that downstream consumers could not process."
  value = {
    arn  = aws_sqs_queue.processing_dlq.arn
    name = aws_sqs_queue.processing_dlq.name
    url  = aws_sqs_queue.processing_dlq.url
  }
}

output "delivery_dlq" {
  description = "Queue containing events that EventBridge could not deliver to the durable event queue."
  value = {
    arn  = aws_sqs_queue.delivery_dlq.arn
    name = aws_sqs_queue.delivery_dlq.name
    url  = aws_sqs_queue.delivery_dlq.url
  }
}

output "archive_arn" {
  description = "ARN of the optional EventBridge replay archive."
  value       = try(aws_cloudwatch_event_archive.salesforce[0].arn, null)
}

output "schema_discoverer_arn" {
  description = "ARN of the optional EventBridge schema discoverer."
  value       = try(aws_schemas_discoverer.salesforce[0].arn, null)
}

output "dashboard_name" {
  description = "Name of the optional CloudWatch operations dashboard."
  value       = try(aws_cloudwatch_dashboard.salesforce[0].dashboard_name, null)
}

output "metric_dimensions" {
  description = "CloudWatch dimensions that can be used to query actual adoption, throughput, latency, and reliability."
  value = {
    partner_source = {
      EventSourceName = data.aws_cloudwatch_event_source.salesforce.name
    }
    eventbridge = {
      EventBusName = local.event_bus_name
      RuleName     = aws_cloudwatch_event_rule.salesforce.name
    }
    event_queue = {
      QueueName = aws_sqs_queue.events.name
    }
    delivery_dlq = {
      QueueName = aws_sqs_queue.delivery_dlq.name
    }
    processing_dlq = {
      QueueName = aws_sqs_queue.processing_dlq.name
    }
  }
}
