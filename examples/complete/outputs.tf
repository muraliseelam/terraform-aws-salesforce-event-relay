output "event_bus" {
  value = module.salesforce_event_relay.event_bus
}

output "event_queue" {
  value = module.salesforce_event_relay.event_queue
}

output "consumer_iam_policy_json" {
  value = module.salesforce_event_relay.consumer_iam_policy_json
}

output "dashboard_name" {
  value = module.salesforce_event_relay.dashboard_name
}
