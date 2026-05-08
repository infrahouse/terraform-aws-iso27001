# Architecture

![Architecture](assets/architecture.svg)

## Resource Classification

The module manages two categories of resources:

### Global Resources (created once)

These are account-level and apply regardless of region:

| Resource | Purpose |
|----------|---------|
| `aws_account_primary_contact` | Account primary contact |
| `aws_account_alternate_contact` | Security contact |
| `aws_iam_account_password_policy` | IAM password policy |
| `aws_s3_account_public_access_block` | Block public S3 access |
| `aws_iam_role` (vanta-auditor) | Vanta compliance scanner (SecurityAudit + Identity Store read) |
| `aws_iam_role` (InfraHouseGovernance) | Cross-account governance (log retention + Lambda tagging) |
| `aws_iam_role` (InfraHouseLogRetention) | Cross-account log retention (**deprecated** — superseded by InfraHouseGovernance) |
| `aws_iam_role` (guardduty-publish) | EventBridge to SNS for GuardDuty |

### Regional Resources (created per region)

These are deployed in each region specified in `var.regions`:

| Resource | Purpose |
|----------|---------|
| `aws_ebs_encryption_by_default` | EBS encryption |
| `aws_accessanalyzer_analyzer` | IAM Access Analyzer |
| `aws_guardduty_detector` | Threat detection |
| `aws_guardduty_detector_feature` | GuardDuty features |
| `aws_cloudwatch_event_rule` | GuardDuty finding events |
| `aws_sns_topic` | GuardDuty notifications |
| `aws_default_security_group` | Lock down default SGs |

## How Multi-Region Works

The module uses the AWS provider v6 `region` argument on each regional
resource. This allows a single module deployment to manage resources
across multiple regions without provider aliases:

```hcl
resource "aws_ebs_encryption_by_default" "this" {
  for_each = toset(var.regions)
  enabled  = true
  region   = each.key
}
```

## Vanta Auditor Role

The `vanta-auditor` IAM role allows Vanta's scanner
(`arn:aws:iam::956993596390:role/scanner`) to audit the account. The trust
policy requires an external ID read from SSM parameter `/vanta/external_id`,
which is distributed to all member accounts by the org-governance StackSet.

Attached policies:

- **SecurityAudit** (AWS managed) — broad read-only access for compliance
  scanning.
- **VantaAdditionalPermissions** (custom) — Identity Store read actions
  (`identitystore:Describe*`, `List*`, `Get*`, `IsMemberInGroups`) plus
  explicit denies on `datapipeline:EvaluateExpression`,
  `datapipeline:QueryObjects`, and `rds:DownloadDBLogFilePortion`.

## Cross-Account Governance Roles

This module deploys two cross-account IAM roles intended for use with
[terraform-aws-org-governance](https://github.com/infrahouse/terraform-aws-org-governance).
Both trust the management account root.

### `InfraHouseGovernance` (current)

Scoped to the broader set of read+tag operations the org-governance Lambda
needs. Permissions:

- `logs:DescribeLogGroups`, `logs:PutRetentionPolicy`,
  `logs:ListTagsForResource`, `logs:TagResource`, `logs:UntagResource` —
  enforce retention policies and tag Control Tower-managed log groups
  (e.g. for Vanta exclusion) without granting read access to log events.
- `lambda:ListFunctions`, `lambda:ListTags`, `lambda:TagResource` — tag
  Control Tower-managed Lambda functions with `VantaNoAlert=true` to mark
  them out of scope for Vanta's inventory checks.

Control Tower-managed log groups are blocked from retention changes by the
`GRLOGGROUPPOLICY` SCP, so the org-governance Lambda tags them with
`VantaNoAlert=true` instead. The same pattern applies to Control
Tower-managed Lambda functions.

### `InfraHouseLogRetention` (deprecated)

Original log-retention-only role, kept in place during the migration to
`InfraHouseGovernance`. Both roles are deployed together for one release
cycle; `InfraHouseLogRetention` will be removed in the next major release.
See
[issue #29](https://github.com/infrahouse/terraform-aws-iso27001/issues/29)
for the deprecation timeline and rationale.

![Cross-Account Log Retention](assets/cross-account-log-retention.svg)

## Control Tower VPC Handling

The module discovers Control Tower VPCs (tagged `aws-controltower-VPC`) in
each region and locks down their default security groups to deny all traffic.
