# Upgrading to 2.1.0

## What changed

This release takes ownership of the `/aws/guardduty/malware-scan-events`
CloudWatch log group to enforce 365-day retention (ISO 27001 standard).
GuardDuty Malware Protection creates this log group on-demand with a 90-day
default, which failed Vanta's retention check.

- **New resource**: `aws_cloudwatch_log_group.malware_scan_events` (one per
  region in `var.regions`)
- **New variable**: `guardduty_log_retention_days` (number, default `365`)

No breaking changes -- the variable has a sensible default and the resource
is additive.

## Migration Steps

### 1. Import existing log groups (per account, per region)

If GuardDuty has already created the log group in an account/region, Terraform
would try to recreate it on the next apply -- import it first. With AWS
provider v6 per-resource `region`, set `AWS_REGION` to match the instance key:

```shell
for region in us-east-1 us-east-2 us-west-1 us-west-2; do
  AWS_REGION=$region terraform import \
    "module.iso27001.aws_cloudwatch_log_group.malware_scan_events[\"${region}\"]" \
    /aws/guardduty/malware-scan-events
done
```

If the log group doesn't exist in a given region, **skip the import for that
region** -- `terraform apply` will create it with the configured retention.
Import errors for missing log groups are expected and safe to ignore.

### 2. Apply

```shell
terraform plan
terraform apply
```

The plan should show:
- `aws_cloudwatch_log_group.malware_scan_events["<region>"]` **updated in place**
  (retention `90` → `365`) where the group was imported
- `aws_cloudwatch_log_group.malware_scan_events["<region>"]` **created** where
  GuardDuty hadn't yet instantiated it

# Upgrading to 2.0.0

## Breaking Changes

- **AWS provider v5 dropped** -- requires `>= 6.0`
- **`regions` variable required** -- replaces per-region module instances
- **`AWSControlTowerExecution` removed** -- Control Tower manages this role
- **GuardDuty module inlined** -- `terraform-aws-guardduty-configuration`
  is no longer a dependency

## Migration Steps

### 1. Remove AWSControlTowerExecution from state

The role is now managed by Control Tower. Remove it from Terraform state
to avoid destroying it:

```shell
terraform state rm \
  'module.iso27001_us_east_1.aws_iam_role_policy_attachment.AdministratorAccess[0]'
terraform state rm \
  'module.iso27001_us_east_1.aws_iam_role.AWSControlTowerExecution[0]'
```

### 2. Replace four module instances with one

**Before (v1.x):**
```hcl
module "iso27001_us_east_1" {
  source    = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version   = "1.3.0"
  providers = { aws = aws.ue1 }
  primary_contact  = local.primary_contact
  security_contact = local.security_contact
}
module "iso27001_us_west_2" {
  source    = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version   = "1.3.0"
  providers = { aws = aws.uw2 }
  primary_contact  = local.primary_contact
  security_contact = local.security_contact
}
# ... repeated for each region
```

**After (v2.0.0):**
```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version = "2.0.0"

  regions = ["us-east-1", "us-east-2", "us-west-1", "us-west-2"]

  primary_contact  = local.primary_contact
  security_contact = local.security_contact
}
```

### 3. Move state from old module instances to the new one

**Global resources** (from the us-east-1 instance -- remove `[0]` index):

```shell
terraform state mv \
  'module.iso27001_us_east_1.aws_account_primary_contact.this[0]' \
  'module.iso27001.aws_account_primary_contact.this'
terraform state mv \
  'module.iso27001_us_east_1.aws_account_alternate_contact.security[0]' \
  'module.iso27001.aws_account_alternate_contact.security'
terraform state mv \
  'module.iso27001_us_east_1.aws_iam_account_password_policy.strict[0]' \
  'module.iso27001.aws_iam_account_password_policy.strict'
terraform state mv \
  'module.iso27001_us_east_1.aws_s3_account_public_access_block.current[0]' \
  'module.iso27001.aws_s3_account_public_access_block.current'
```

**Regional resources** (for each region):

```shell
for region in us-east-1 us-east-2 us-west-1 us-west-2; do
  suffix=$(echo $region | sed 's/-/_/g')

  terraform state mv \
    "module.iso27001_${suffix}.aws_ebs_encryption_by_default.this" \
    "module.iso27001.aws_ebs_encryption_by_default.this[\"${region}\"]"

  terraform state mv \
    "module.iso27001_${suffix}.aws_accessanalyzer_analyzer.external_access" \
    "module.iso27001.aws_accessanalyzer_analyzer.external_access[\"${region}\"]"
done
```

**GuardDuty resources** (for each region):

```shell
for region in us-east-1 us-east-2 us-west-1 us-west-2; do
  suffix=$(echo $region | sed 's/-/_/g')

  terraform state mv \
    "module.iso27001_${suffix}.module.guardduty.aws_guardduty_detector.main" \
    "module.iso27001.aws_guardduty_detector.main[\"${region}\"]"

  terraform state mv \
    "module.iso27001_${suffix}.module.guardduty.aws_cloudwatch_event_rule.guardduty_findings" \
    "module.iso27001.aws_cloudwatch_event_rule.guardduty_findings[\"${region}\"]"

  terraform state mv \
    "module.iso27001_${suffix}.module.guardduty.aws_sns_topic.notifications" \
    "module.iso27001.aws_sns_topic.guardduty_notifications[\"${region}\"]"

  terraform state mv \
    "module.iso27001_${suffix}.module.guardduty.aws_sns_topic_subscription.emails" \
    "module.iso27001.aws_sns_topic_subscription.guardduty_emails[\"${region}\"]"

  terraform state mv \
    "module.iso27001_${suffix}.module.guardduty.aws_cloudwatch_event_target.notify_target" \
    "module.iso27001.aws_cloudwatch_event_target.guardduty_notify[\"${region}\"]"
done
```

**VPC default security groups** (composite key changes):

```shell
# For each region, list the VPC IDs in state, then move them:
# Old: module.iso27001_us_east_1.aws_default_security_group.default["vpc-abc"]
# New: module.iso27001.aws_default_security_group.default["us-east-1/vpc-abc"]
```

**GuardDuty IAM role** (global, pick one instance):

```shell
terraform state mv \
  'module.iso27001_us_east_1.module.guardduty.aws_iam_role.guardduty' \
  'module.iso27001.aws_iam_role.guardduty'
terraform state mv \
  'module.iso27001_us_east_1.module.guardduty.aws_iam_policy.guardduty' \
  'module.iso27001.aws_iam_policy.guardduty'
terraform state mv \
  'module.iso27001_us_east_1.module.guardduty.aws_iam_role_policy_attachment.guardduty' \
  'module.iso27001.aws_iam_role_policy_attachment.guardduty'

# Remove duplicates from other regions
for suffix in us_east_2 us_west_1 us_west_2; do
  terraform state rm "module.iso27001_${suffix}.module.guardduty.aws_iam_role.guardduty"
  terraform state rm "module.iso27001_${suffix}.module.guardduty.aws_iam_policy.guardduty"
  terraform state rm "module.iso27001_${suffix}.module.guardduty.aws_iam_role_policy_attachment.guardduty"
done
```

### 4. Verify

```shell
terraform plan
```

The plan should show the new `InfraHouseLogRetention` resources being
created and no unexpected destroys. GuardDuty detector features may show
updates due to the `for_each` key change.
