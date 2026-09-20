# End-to-end validation record

Copy this file to `docs/validation-YYYY-MM-DD.md`, replace every `FILL IN`, and commit it. A line you cannot answer is still evidence: write `Not measured` rather than deleting the line or estimating a number.

Redact before committing, as `CONTRIBUTING.md` requires:

- AWS account IDs become `123456789012`, and ARNs keep their shape with that account ID.
- The Salesforce org and relay identifiers become `00Dxxxxxxxxxxxxxxx` and `0YLxxxxxxxxxxxxxxx`.
- Queue, rule, and dashboard names may stay only if they carry no account or org identifier.
- No event payloads. Record the field count and byte size if the shape matters, never the values.
- No credentials, named-credential settings, or consumer connection strings.

## Scope

| Field | Value |
|---|---|
| Date of run (UTC) | FILL IN |
| Module version | FILL IN, for example `v0.1.2` |
| Terraform version | FILL IN |
| AWS provider version | FILL IN |
| AWS region | FILL IN |
| AWS account | non-production; FILL IN which environment |
| Salesforce org | FILL IN: sandbox, scratch, or developer edition |
| Channel | FILL IN: the CDC object or Platform Event channel |
| Run by | FILL IN |

## Configuration applied

Module inputs that differ from the defaults, with any account or org identifier redacted:

```hcl
FILL IN
```

The `terraform apply` summary line:

```text
FILL IN, for example: Apply complete! Resources: 17 added, 0 changed, 0 destroyed.
```

## The test event

- What was changed or published to generate it: FILL IN
- Publish time (UTC): FILL IN
- Payload shape: FILL IN field count and byte size, no values

## Delivery evidence

Read the names and URLs from the module rather than typing them by hand:

```shell
terraform output -json metric_dimensions
terraform output -json delivery_dlq
terraform output -json processing_dlq
```

Then collect the numbers, replacing `BUS_NAME`, `RULE_NAME`, `QUEUE_NAME` and the two URLs with those values, and `START` and `END` with ISO-8601 UTC timestamps bracketing the run:

```shell
aws cloudwatch get-metric-statistics --namespace AWS/Events --metric-name MatchedEvents --dimensions Name=EventBusName,Value=BUS_NAME Name=RuleName,Value=RULE_NAME --start-time START --end-time END --period 300 --statistics Sum
aws cloudwatch get-metric-statistics --namespace AWS/SQS --metric-name NumberOfMessagesSent --dimensions Name=QueueName,Value=QUEUE_NAME --start-time START --end-time END --period 300 --statistics Sum
aws sqs get-queue-attributes --queue-url DELIVERY_DLQ_URL --attribute-names ApproximateNumberOfMessagesVisible
aws sqs get-queue-attributes --queue-url PROCESSING_DLQ_URL --attribute-names ApproximateNumberOfMessagesVisible
```

| Check | Result |
|---|---|
| `MatchedEvents` sum over the run window | FILL IN |
| `NumberOfMessagesSent` on the main queue | FILL IN |
| A consumer received and deleted the event | FILL IN how, and whether it succeeded |
| Delivery DLQ `ApproximateNumberOfMessagesVisible` | FILL IN |
| Processing DLQ `ApproximateNumberOfMessagesVisible` | FILL IN |

## Latency

| Measurement | Value | How it was measured |
|---|---|---|
| Salesforce publish to queue arrival | FILL IN or `Not measured` | FILL IN |

One event measures reachability, not latency under load. Say so plainly if that is all this run established.

## What this run does not establish

- Throughput at production volume: FILL IN or `Not measured`.
- Cost per million events: FILL IN or `Not measured`.
- Behavior during a Salesforce or AWS outage: FILL IN or `Not measured`.
- Consumer-side processing performance: FILL IN or `Not measured`.

## Anything that failed or surprised you

FILL IN, including alarms that fired, retries observed, and anything the documentation got wrong. A record with no problems in it is less useful, not more.

## Cleanup

- Resources destroyed after the run: FILL IN yes or no.
- If kept: FILL IN why, and who owns them.

## Sign-off

FILL IN name, and the date the record was written if it differs from the date of the run.
