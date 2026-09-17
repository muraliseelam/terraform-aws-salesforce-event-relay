output "event_bus" {
  description = "Existing EventBridge partner event bus derived from the active Salesforce source."
  value       = module.salesforce_event_relay.event_bus
}

output "event_queue" {
  description = "Durable queue consumed by downstream Salesforce event processors."
  value       = module.salesforce_event_relay.event_queue
}

output "consumer_iam_policy_json" {
  description = "Least-privilege IAM policy document for a queue consumer."
  value       = module.salesforce_event_relay.consumer_iam_policy_json
}
