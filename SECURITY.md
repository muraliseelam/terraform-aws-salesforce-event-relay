# Security policy

## Reporting

Report suspected vulnerabilities privately to the repository maintainers. Do not include Salesforce credentials, access tokens, event payloads, customer data, or Terraform state in an issue.

## Security model

The module:

- relies on the native Salesforce Event Relay partner source;
- encrypts SQS queues at rest with SQS-managed keys;
- denies non-TLS SQS requests;
- limits EventBridge queue writes by service principal, source rule ARN, and source AWS account;
- creates separate delivery and processing dead-letter queues;
- avoids payload logging;
- exposes only queue-consumer permissions, not producer or administrative permissions.

The module does not configure Salesforce users, credentials, Event Relay channels, downstream consumers, network egress, or organization-wide AWS controls. Those remain the caller's responsibility.

Before production use, classify the event fields, minimize the payload, constrain consumer roles, configure alarm notifications, test DLQ recovery, and verify that archive retention satisfies organizational policy.
