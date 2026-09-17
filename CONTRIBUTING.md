# Contributing

Thank you for helping improve this module. It is published to the public Terraform Registry, so every change is read by people deciding whether to depend on it. Correctness and honest documentation matter more than speed.

## Before you start

- Terraform 1.7 or later (CI pins 1.12.2) and the AWS provider 6.x.
- [TFLint](https://github.com/terraform-linters/tflint) 0.64 or later for linting.
- No AWS account or Salesforce org is required for the checks below. The native tests use a mocked AWS provider and never create resources.

## Local checks

Run all of these before opening a pull request. CI runs the same commands.

```shell
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
tflint --init
tflint --config "$(pwd)/.tflint.hcl"
tflint --chdir examples/complete --config "$(pwd)/.tflint.hcl"
tflint --chdir examples/existing-bus --config "$(pwd)/.tflint.hcl"
```

Every behavioral change needs a test in `tests/`. Prefer assertions on the exact attribute that changed over assertions that only check a resource exists.

## Security properties

The following properties are the point of this module. A change that weakens any of them must be proposed in an issue first and called out explicitly in the pull request description:

- all queues use SQS-managed server-side encryption;
- every queue policy denies non-TLS requests;
- EventBridge may write to a queue only from the managed rule ARN in the deploying AWS account;
- the consumer policy grants only receive, delete, visibility, and attribute actions on the main queue;
- Salesforce event payloads are never written to CloudWatch Logs or exposed in outputs;
- schema discovery stays opt-in.

## What never goes into the repository

- Terraform state, plan files, or `.terraform/` directories.
- AWS account IDs, ARNs from real accounts, or credentials.
- Salesforce org IDs, usernames, access tokens, or event payloads. Use the placeholder source name `aws.partner/salesforce.com/00Dxxxxxxxxxxxxxxx/0YLxxxxxxxxxxxxxxx` in documentation and tests.
- Measurements that were not actually taken. If something has not been measured, say so rather than estimating.

## Commit messages

- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`, `refactor:`. Mark breaking changes with `!` and a `BREAKING CHANGE:` footer.
- Do not add tool-generated `Co-authored-by` trailers for AI assistants. In VS Code, set `"git.addAICoAuthor": "off"` so the Copilot trailer is not appended automatically, and review the full message with `git log -1 --format=%B` before pushing.
- Sign tags and, where possible, commits.

## Releases

Maintainers release by updating `CHANGELOG.md`, updating the version in the README usage block, and pushing an annotated, signed tag such as `v0.1.2`. The public Terraform Registry publishes the new version automatically from the tag. Published tags are never moved or deleted, because consumers pin them.

Do not tag `v1.0.0` until a non-production Salesforce Event Relay has delivered a representative test event through the module and the result is recorded in the repository.
