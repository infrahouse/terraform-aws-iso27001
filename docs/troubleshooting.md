# Troubleshooting

## Common Issues

### GuardDuty detector already exists

```
Error: creating GuardDuty Detector: BadRequestException:
The request is rejected because the current account already has
a GuardDuty detector enabled in the given region
```

GuardDuty may have been enabled manually or by another tool. Import the
existing detector:

```shell
terraform import \
  'module.iso27001.aws_guardduty_detector.main["us-east-1"]' \
  DETECTOR_ID
```

Find the detector ID with:
```shell
aws guardduty list-detectors --region us-east-1
```

### Access Analyzer already exists

```
Error: creating IAM Access Analyzer: ConflictException:
An analyzer with the same name already exists
```

Import the existing analyzer:
```shell
terraform import \
  'module.iso27001.aws_accessanalyzer_analyzer.external_access["us-east-1"]' \
  external-access-analyzer
```

### Organizations API access denied

```
Error: reading AWS Organization: AccessDeniedException
```

The module calls `data.aws_organizations_organization` to discover the
management account ID (used for the InfraHouseLogRetention trust policy).
The calling role needs `organizations:DescribeOrganization` permission.

### SNS subscription not confirmed

After applying, the security contact email receives a subscription
confirmation from each region's GuardDuty SNS topic. Findings won't be
delivered until the subscription is confirmed.

Check pending subscriptions:
```shell
aws sns list-subscriptions --region us-east-1 | \
  jq '.Subscriptions[] | select(.SubscriptionArn == "PendingConfirmation")'
```
