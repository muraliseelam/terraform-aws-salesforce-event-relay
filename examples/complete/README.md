# Complete CDC example

This example associates a pending Salesforce partner event source, routes Account and Contact CDC events to SQS, retains events for 90 days, enables schema discovery, and creates monitoring.

```shell
terraform init
terraform plan -var='partner_event_source_name_prefix=aws.partner/salesforce.com/00Dxxxxxxxxxxxxxxx/0YLxxxxxxxxxxxxxxx'
terraform apply -var='partner_event_source_name_prefix=aws.partner/salesforce.com/00Dxxxxxxxxxxxxxxx/0YLxxxxxxxxxxxxxxx'
```

Use a non-production Salesforce org for the first deployment. Start the Salesforce relay only after the partner event bus is associated.
