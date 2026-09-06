# Salesforce and AWS setup sequence

Salesforce creates the EventBridge partner event source; Terraform then associates it with a partner event bus. Run the steps in this order.

## 1. Select events

Choose the minimum set of events needed by the integration:

- enable Change Data Capture only for required Salesforce objects; or
- create a custom Platform Event channel and add only the required Platform Events.

Avoid relaying fields that downstream services do not need.

## 2. Configure AWS access in Salesforce

Create the Salesforce external credential and named credential required by Event Relay. Scope the AWS identity to the permissions documented by Salesforce for creating and operating its EventBridge partner event source. Store credentials only in Salesforce's credential facilities, never in Terraform variables or state.

Follow the current [Salesforce Event Relay documentation](https://developer.salesforce.com/docs/platform/event-relay/overview) because setup labels and supported authentication methods can change between Salesforce releases.

## 3. Create the Event Relay configuration

Create the relay for the selected channel. Salesforce creates an EventBridge partner event source in the `PENDING` state. Record its full source name from AWS EventBridge. It resembles:

```text
aws.partner/salesforce.com/00Dxxxxxxxxxxxxxxx/0YLxxxxxxxxxxxxxxx
```

The final segment is the Salesforce Event Relay configuration ID, not its friendly name. Copy the exact source name from **AWS EventBridge > Partner event sources** or from `aws events list-event-sources`. Do not manually associate the source if Terraform will manage the event bus.

## 4. Apply this module

Pass enough of the source name to match exactly one source:

```hcl
partner_event_source_name_prefix = "aws.partner/salesforce.com/00Dxxxxxxxxxxxxxxx/0YLxxxxxxxxxxxxxxx"
```

Apply in the same AWS account and region where Salesforce created the source. The module associates the source, creates the event rule and queues, and configures monitoring.

If the partner source is already associated, use `associate_partner_event_source = false`. To bring an existing bus under management, import it as shown in the root README.

## 5. Start the relay

Return to Salesforce and start the Event Relay. Publish a non-sensitive test event, then confirm:

1. EventBridge `MatchedEvents` increases.
2. `NumberOfMessagesSent` increases on the main queue.
3. A test consumer can receive and delete the event.
4. Both DLQs remain empty.

AWS also documents the integration in [Receiving events from Salesforce in Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-saas-salesforce.html).
