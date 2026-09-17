mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/terraform-test"
      user_id    = "AIDATEST"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      dns_suffix         = "amazonaws.com"
      id                 = "aws"
      partition          = "aws"
      reverse_dns_prefix = "com.amazonaws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      description = "US East (N. Virginia)"
      endpoint    = "ec2.us-east-1.amazonaws.com"
      region      = "us-east-1"
    }
  }

  mock_data "aws_cloudwatch_event_source" {
    defaults = {
      arn        = "arn:aws:events:us-east-1:123456789012:event-source/aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
      created_by = "salesforce.com"
      name       = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
      state      = "PENDING"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json          = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
      minified_json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_cloudwatch_event_bus" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:event-bus/aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    }
  }

  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:rule/aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA/sf-event-relay-route"
    }
  }

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
      id  = "https://sqs.us-east-1.amazonaws.com/123456789012/mock-queue"
      url = "https://sqs.us-east-1.amazonaws.com/123456789012/mock-queue"
    }
  }
}

run "secure_defaults" {
  command = apply

  variables {
    partner_event_source_name_prefix = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
  }

  assert {
    condition     = length(aws_cloudwatch_event_bus.salesforce) == 1
    error_message = "The module should associate the pending partner source by default."
  }

  assert {
    condition     = aws_sqs_queue.events.sqs_managed_sse_enabled
    error_message = "The main event queue must be encrypted."
  }

  assert {
    condition     = aws_sqs_queue.delivery_dlq.sqs_managed_sse_enabled && aws_sqs_queue.processing_dlq.sqs_managed_sse_enabled
    error_message = "Both dead-letter queues must be encrypted."
  }

  assert {
    condition = aws_cloudwatch_event_rule.salesforce.event_pattern == jsonencode({
      source = ["aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"]
    })
    error_message = "The default rule must restrict events to the discovered Salesforce source."
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.salesforce) == 1
    error_message = "Replay archiving should be enabled by default."
  }

  assert {
    condition     = length(aws_schemas_discoverer.salesforce) == 0
    error_message = "Schema discovery should require explicit opt-in."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.eventbridge) == 4
    error_message = "All EventBridge failure alarms should be created by default."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.eventbridge["events-sent-to-dlq"].metric_name == "InvocationsSentToDlq" &&
      aws_cloudwatch_metric_alarm.eventbridge["dlq-delivery-failures"].metric_name == "InvocationsFailedToBeSentToDlq" &&
      aws_cloudwatch_metric_alarm.eventbridge["retry-attempts"].metric_name == "RetryInvocationAttempts"
    )
    error_message = "EventBridge alarms must use the exact case-sensitive AWS metric names."
  }

  assert {
    condition = alltrue([
      for alarm in aws_cloudwatch_metric_alarm.eventbridge :
      alarm.dimensions["EventBusName"] == "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA" &&
      alarm.dimensions["RuleName"] == "sf-event-relay-route" &&
      length(keys(alarm.dimensions)) == 2
    ])
    error_message = "Custom and partner bus rule metrics must use EventBusName and RuleName dimensions."
  }

  assert {
    condition     = jsondecode(aws_sqs_queue.events.redrive_policy).maxReceiveCount == 5
    error_message = "The main queue must redrive repeatedly failed messages to the processing DLQ."
  }

  assert {
    condition = (
      aws_cloudwatch_event_target.events.retry_policy[0].maximum_event_age_in_seconds == 86400 &&
      aws_cloudwatch_event_target.events.retry_policy[0].maximum_retry_attempts == 185
    )
    error_message = "The EventBridge target must apply the configured retry policy."
  }

  assert {
    condition     = aws_cloudwatch_event_target.events.dead_letter_config[0].arn == aws_sqs_queue.delivery_dlq.arn
    error_message = "The EventBridge target must send exhausted deliveries to the delivery DLQ."
  }

  assert {
    condition     = length(aws_cloudwatch_dashboard.salesforce) == 1
    error_message = "The operations dashboard should be created by default."
  }
}

run "optional_features_and_existing_bus" {
  command = plan

  variables {
    partner_event_source_name_prefix = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    associate_partner_event_source   = false
    enable_archive                   = false
    enable_schema_discovery          = true
    enable_dashboard                 = false
    enable_alarms                    = false
    event_pattern = jsonencode({
      "detail-type" = ["AccountChangeEvent"]
      detail = {
        payload = {
          ChangeEventHeader = {
            changeType = ["UPDATE"]
          }
        }
      }
    })
  }

  assert {
    condition     = length(aws_cloudwatch_event_bus.salesforce) == 0
    error_message = "Existing-bus mode must not create another partner bus."
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.salesforce) == 0
    error_message = "Archiving must be removable."
  }

  assert {
    condition     = length(aws_schemas_discoverer.salesforce) == 1
    error_message = "Schema discovery must be created when enabled."
  }

  assert {
    condition = aws_cloudwatch_event_rule.salesforce.event_pattern == jsonencode({
      "detail-type" = ["AccountChangeEvent"]
      detail = {
        payload = {
          ChangeEventHeader = {
            changeType = ["UPDATE"]
          }
        }
      }
    })
    error_message = "A caller-supplied event pattern must replace the default pattern."
  }

  assert {
    condition     = output.event_bus.arn == "arn:aws:events:us-east-1:123456789012:event-bus/aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    error_message = "Existing-bus mode must derive the standard partner event bus ARN."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.eventbridge) == 0 && length(aws_cloudwatch_dashboard.salesforce) == 0
    error_message = "Monitoring resources must honor their feature flags."
  }
}

run "reject_non_salesforce_source" {
  command = plan

  variables {
    partner_event_source_name_prefix = "aws.partner/example.com/not-salesforce"
  }

  expect_failures = [var.partner_event_source_name_prefix]
}

run "reject_short_processing_dlq_retention" {
  command = plan

  variables {
    partner_event_source_name_prefix = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    queue_message_retention_seconds  = 345600
    processing_dlq_retention_seconds = 86400
  }

  expect_failures = [aws_sqs_queue.events]
}

run "security_invariants" {
  command = apply

  variables {
    partner_event_source_name_prefix = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
  }

  assert {
    condition = alltrue([
      for queue in [aws_sqs_queue.events, aws_sqs_queue.delivery_dlq, aws_sqs_queue.processing_dlq] :
      queue.sqs_managed_sse_enabled && queue.tags["ManagedBy"] == "Terraform"
    ])
    error_message = "Every queue must use SQS-managed encryption and carry the ManagedBy tag."
  }

  assert {
    condition = alltrue([
      for document in [
        data.aws_iam_policy_document.events_queue,
        data.aws_iam_policy_document.delivery_dlq,
        data.aws_iam_policy_document.processing_dlq
      ] :
      document.statement[0].sid == "DenyInsecureTransport" &&
      document.statement[0].effect == "Deny" &&
      document.statement[0].actions == toset(["sqs:*"]) &&
      length(document.statement[0].condition) == 1 &&
      one(document.statement[0].condition).test == "Bool" &&
      one(document.statement[0].condition).variable == "aws:SecureTransport" &&
      one(document.statement[0].condition).values == tolist(["false"])
    ])
    error_message = "Every queue policy must start with a statement denying non-TLS access."
  }

  assert {
    condition = alltrue([
      for document in [data.aws_iam_policy_document.events_queue, data.aws_iam_policy_document.delivery_dlq] :
      length(document.statement) == 2 &&
      document.statement[1].effect == "Allow" &&
      document.statement[1].actions == toset(["sqs:SendMessage"]) &&
      length(document.statement[1].principals) == 1 &&
      one(document.statement[1].principals).type == "Service" &&
      one(document.statement[1].principals).identifiers == toset(["events.amazonaws.com"]) &&
      length(document.statement[1].condition) == 2 &&
      anytrue([
        for condition in document.statement[1].condition :
        condition.test == "ArnEquals" &&
        condition.variable == "aws:SourceArn" &&
        condition.values == tolist([aws_cloudwatch_event_rule.salesforce.arn])
      ]) &&
      anytrue([
        for condition in document.statement[1].condition :
        condition.test == "StringEquals" &&
        condition.variable == "aws:SourceAccount" &&
        condition.values == tolist(["123456789012"])
      ])
    ])
    error_message = "EventBridge may send messages only from the managed rule in the deploying account."
  }

  assert {
    condition     = length(data.aws_iam_policy_document.processing_dlq.statement) == 1
    error_message = "The processing DLQ must not grant any producer access; only SQS redrive writes to it."
  }

  assert {
    condition = (
      length(data.aws_iam_policy_document.consumer.statement) == 1 &&
      length(data.aws_iam_policy_document.consumer.statement[0].principals) == 0 &&
      data.aws_iam_policy_document.consumer.statement[0].actions == toset([
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage"
      ]) &&
      data.aws_iam_policy_document.consumer.statement[0].resources == toset([aws_sqs_queue.events.arn])
    )
    error_message = "The consumer policy must grant only receive, delete, visibility, and attribute actions on the main queue."
  }

  assert {
    condition = (
      jsondecode(aws_sqs_queue_redrive_allow_policy.processing_dlq.redrive_allow_policy).redrivePermission == "byQueue" &&
      jsondecode(aws_sqs_queue_redrive_allow_policy.processing_dlq.redrive_allow_policy).sourceQueueArns == [aws_sqs_queue.events.arn]
    )
    error_message = "Only the main queue may redrive into the processing DLQ."
  }

  assert {
    condition     = aws_sqs_queue.delivery_dlq.message_retention_seconds == 1209600
    error_message = "The delivery DLQ must retain undeliverable events for the SQS maximum of 14 days."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.salesforce.state == "ENABLED" && aws_cloudwatch_event_rule.salesforce.event_bus_name == "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    error_message = "The routing rule must be enabled on the Salesforce partner bus."
  }
}

run "reject_invalid_name" {
  command = plan

  variables {
    partner_event_source_name_prefix = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    name                             = "bad name!"
  }

  expect_failures = [var.name]
}

run "reject_invalid_event_pattern" {
  command = plan

  variables {
    partner_event_source_name_prefix = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    event_pattern                    = "not-json"
  }

  expect_failures = [var.event_pattern]
}

run "reject_non_arn_alarm_action" {
  command = plan

  variables {
    partner_event_source_name_prefix = "aws.partner/salesforce.com/00D000000000000AAA/0YL000000000000AAA"
    alarm_actions                    = ["platform-alerts"]
  }

  expect_failures = [var.alarm_actions]
}
