# Measuring real-world impact

This document is an engineering evidence plan, not immigration legal advice. Review any EB-1A strategy with qualified counsel.

A module existing in a public registry is proof of implementation and availability, not proof that a contribution has major significance. Stronger evidence connects authorship to independent adoption and measurable outcomes.

## Evidence the project can produce

| Question | Objective artifact |
|---|---|
| Who designed and maintained it? | Git history, reviewed pull requests, release notes, architecture decisions, and signed release tags |
| Was it adopted? | Public registry download counts, GitHub traffic, external consumer workspaces, deployment records, and independent teams using pinned versions |
| Did it solve an important problem? | Before/after integration lead time, incident rate, recovery time, throughput, and cost |
| Was it reliable at meaningful scale? | CloudWatch aggregate metrics for matched events, processed events, backlog age, failures, and replay volume |
| Did others recognize the work? | Specific letters from independent users or leaders, conference invitations, technical reviews, and citations |
| Was knowledge disseminated? | A public article, white paper, conference session, or scholarly/trade publication that explains the design and measured results |

## Suggested baselines

Record a baseline before adoption and use the same definition afterward:

- median days required to onboard a Salesforce event integration;
- deployment failure and rollback rate;
- event delivery success rate;
- mean time to detect and recover from failures;
- monthly event volume;
- duplicate or lost-event incidents;
- infrastructure and operational cost per million events.

The module dashboard supplies infrastructure metrics. Business outcomes and consumer latency must come from the adopting systems.

## Evidence hygiene

1. Record only real deployments and measured results.
2. Preserve dates, version numbers, metric definitions, and the person or system that generated each artifact.
3. Prefer independent corroboration over self-authored claims.
4. Redact credentials, customer data, Salesforce record IDs, and proprietary payloads.
5. Obtain employer or customer permission before publishing internal metrics or architecture.
6. Keep failures and limitations in the record; do not manufacture adoption, testimonials, citations, or impact.

USCIS evaluates evidence in totality and performs a final-merits determination. The current primary guidance is the [USCIS Policy Manual, Volume 6, Part F, Chapter 2](https://www.uscis.gov/policy-manual/volume-6-part-f-chapter-2).
