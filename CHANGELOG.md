# Changelog

All notable changes follow [Semantic Versioning](https://semver.org/).

## [0.1.2] - 2026-09-17

### Added

- Native tests asserting the TLS-only queue policies, EventBridge source ARN and source account conditions, the consumer policy actions, and the redrive allow policy.
- Native tests for the `name`, `event_pattern`, and `alarm_actions` input validations.
- TFLint configuration and a CI lint job for the module and both examples.
- CI validation of both examples.
- `CONTRIBUTING.md` with local checks, security-property change policy, and commit conventions.
- README section listing limitations and known gaps.

### Changed

- Example outputs now carry descriptions, and the existing-bus example exposes outputs.
- Example version constraints exclude Terraform 2.x, matching the root module.

## [0.1.1] - 2026-09-06

### Changed

- Made the Terraform public registry the primary installation source.
- Clarified that the HCP Terraform private registry is only an optional internal mirror.

## [0.1.0] - 2026-09-06

### Added

- Salesforce Event Relay partner source association.
- EventBridge filtering and durable encrypted SQS delivery.
- Separate EventBridge delivery and consumer processing DLQs.
- Event archive, optional schema discovery, dashboards, and alarms.
- Least-privilege consumer IAM policy output.
- Native Terraform tests and complete usage examples.
