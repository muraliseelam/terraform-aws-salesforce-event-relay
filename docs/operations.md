# Operations runbook

## Healthy state

- Salesforce Event Relay is running.
- The partner source and event bus are active.
- EventBridge source-event, matched-event, and target-invocation counts track expected Salesforce volume.
- Queue age remains below the service objective.
- Delivery and processing DLQs are empty.

## Delivery DLQ has messages

Messages in the delivery DLQ mean EventBridge could not deliver an event to the main queue.

1. Inspect message attributes such as `ERROR_CODE`, `ERROR_MESSAGE`, `RULE_ARN`, and `TARGET_ARN`.
2. Verify the queue exists and its resource policy still grants the managed rule `sqs:SendMessage`.
3. Confirm the event rule and target are enabled.
4. Correct the delivery failure.
5. Redrive or republish the event using an approved operational process.

Do not delete failed messages until their disposition is recorded.

## Retry-attempt alarm

`RetryInvocationAttempts` is emitted while EventBridge is retrying a target, before retry age or attempt limits are exhausted. Investigate this alarm immediately; successful retries can prevent a later DLQ message but still indicate degraded delivery.

If the source `Events` metric increases but `MatchedEvents` does not, inspect the rule pattern against an actual Event Relay envelope. Event Relay fields are nested under `detail.payload`.

## Processing DLQ has messages

Messages in the processing DLQ mean a consumer received an event repeatedly but did not complete processing.

1. Correlate the event ID and Salesforce transaction key with consumer logs.
2. Determine whether the payload is malformed, unsupported, or failing because of a downstream dependency.
3. Fix or quarantine the cause.
4. Use SQS redrive to return safe messages to the main queue.
5. Confirm idempotency before replaying.

## Main queue age alarm

An old-message alarm usually indicates insufficient consumer capacity, a failing dependency, or poison messages repeatedly becoming visible.

1. Compare `NumberOfMessagesSent` and `NumberOfMessagesDeleted`.
2. Inspect consumer errors and throttling.
3. Scale consumers within downstream rate limits.
4. Confirm the visibility timeout exceeds normal processing time.
5. Increase timeouts only after identifying the bottleneck.

## EventBridge archive replay

Use an archive replay when a rule or consumer outage affected events that did not reach a recoverable queue. Replays send matching archived events back to the event bus.

Before replaying:

- pause or scale consumers deliberately;
- verify consumer idempotency;
- narrow the replay time range;
- estimate downstream API and database load;
- monitor queue age and both DLQs.

## Metrics to retain

Export or retain approved aggregate metrics for:

- matched events;
- successfully enqueued and deleted messages;
- failed invocations and DLQ deliveries;
- oldest-message age;
- recovery duration and replay volume.

Do not export event payloads as operational evidence.
