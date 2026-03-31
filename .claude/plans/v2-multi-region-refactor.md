# Plan: Refactor iso27001 to single-deployment multi-region module (v2.0.0)

## Context

The module is currently deployed once per region with provider aliases
(4 instances in aws-control-root). Global resources use
`count = us-east-1 ? 1 : 0` to avoid duplication. This is a major
version bump that also:
- Removes `AWSControlTowerExecution` (CT manages it)
- Adds `InfraHouseLogRetention` role
- Drops AWS provider v5 support
- Adds `.checkov.yml`

AWS provider v6 added `region` argument to regional resources, so
the module can manage all regions from a single deployment.

## Changes

### 1. `terraform.tf` — drop v5
```hcl
version = ">= 6.0, < 7.0"
```

### 2. `variables.tf` — add `regions`
```hcl
variable "regions" {
  description = "List of AWS regions to configure regional ISO 27001 controls in."
  type        = list(string)
}
```
No default — caller must be explicit.

### 3. Global resources — remove `count`
These are account-level, applied once regardless of region:
- `contacts.tf`: remove `count` from both resources
- `password_policy.tf`: remove `count`
- `s3.tf`: remove `count`
- `iam.tf`: remove `count` from InfraHouseLogRetention role and policy,
  fix `count.index` reference

### 4. Regional resources — add `for_each` + `region`
- `ebs_encryption.tf`: `for_each = toset(var.regions)`,
  `region = each.key`
- `access-analyzer.tf`: `for_each = toset(var.regions)`,
  `region = each.key`

### 5. `controltower-vpc.tf` — multi-region VPC iteration
Verified: `aws_vpcs` data source supports `region` in v6.

```hcl
data "aws_vpcs" "aws_control_tower_vpc" {
  for_each = toset(var.regions)
  region   = each.key
  filter {
    name   = "tag:Name"
    values = ["aws-controltower-VPC"]
  }
}

locals {
  controltower_vpcs = merge([
    for region, vpcs in data.aws_vpcs.aws_control_tower_vpc : {
      for vpc_id in vpcs.ids : "${region}/${vpc_id}" => {
        region = region
        vpc_id = vpc_id
      }
    }
  ]...)
}

resource "aws_default_security_group" "default" {
  for_each = local.controltower_vpcs
  vpc_id   = each.value.vpc_id
  region   = each.value.region
}
```

### 6. `guardduty.tf` — inline and deprecate external module
Replace `module "guardduty"` with inline resources. All GuardDuty
resources support `region` in v6 (verified). Deprecate
`terraform-aws-guardduty-configuration`.

Resources inlined with `for_each = toset(var.regions)` + `region`:
- `aws_guardduty_detector` — detector per region
- `aws_guardduty_detector_feature` — composite key `region:feature`
- `aws_guardduty_detector_feature` (RUNTIME_MONITORING) — separate
  resource due to provider bug (additional_configuration blocks)
- `aws_cloudwatch_event_rule` — per region
- `aws_cloudwatch_event_target` — per region
- `aws_sns_topic` — per region
- `aws_sns_topic_subscription` — per region

IAM resources (global, created once, no `for_each`):
- `aws_iam_role` — EventBridge→SNS publish role
- `aws_iam_policy` — sns:Publish to all regional topic ARNs
- `aws_iam_role_policy_attachment`

The IAM policy references all regional SNS topic ARNs:
```hcl
resources = [
  for topic in aws_sns_topic.guardduty_notifications :
  topic.arn
]
```

### 7. `data_sources.tf` — remove `data "aws_region" "current"`
No longer needed for conditions.
Keep `data "aws_organizations_organization"`.

### 8. `locals.tf`
- Bump version to `2.0.0`
- Add `controltower_vpcs` local

### 9. Tests
- `test_data/iso27001/variables.tf`: add `regions` variable
- `test_data/iso27001/main.tf`: pass `regions = var.regions`
- `tests/test_module.py`: remove v5 parameterization,
  add `regions = ["{aws_region}"]` to tfvars

### 10. `README.md` — migration guide
Expand the "Upgrading to 2.0.0" section with:
- `terraform state rm` for AWSControlTowerExecution (already written)
- `terraform state mv` commands for going from 4 module instances to 1
- New usage example with `regions`

### Migration commands for existing deployments

```shell
# Remove AWSControlTowerExecution from state
terraform state rm \
  'module.iso27001_us_east_1.aws_iam_role_policy_attachment.AdministratorAccess[0]'
terraform state rm \
  'module.iso27001_us_east_1.aws_iam_role.AWSControlTowerExecution[0]'

# Global resources (from the us-east-1 instance, drop [0] index)
terraform state mv \
  'module.iso27001_us_east_1.aws_account_primary_contact.this[0]' \
  'module.iso27001.aws_account_primary_contact.this'
# ... (similar for alternate_contact, password_policy, s3_block,
#      IAM role)

# Regional resources (for each region)
for region in us-east-1 us-east-2 us-west-1 us-west-2; do
  suffix=$(echo $region | sed 's/-/_/g')
  terraform state mv \
    "module.iso27001_${suffix}.aws_ebs_encryption_by_default.this" \
    "module.iso27001.aws_ebs_encryption_by_default.this[\"${region}\"]"
  terraform state mv \
    "module.iso27001_${suffix}.aws_accessanalyzer_analyzer.external_access" \
    "module.iso27001.aws_accessanalyzer_analyzer.external_access[\"${region}\"]"

  # GuardDuty (was module.guardduty inside each iso27001 instance)
  terraform state mv \
    "module.iso27001_${suffix}.module.guardduty.aws_guardduty_detector.main" \
    "module.iso27001.aws_guardduty_detector.main[\"${region}\"]"
  # GuardDuty features, SNS, EventBridge — similar pattern
  # (full list in docs/upgrading-to-2.0.md)
done
```

## Verification
1. `terraform fmt -check` — formatting
2. `checkov -d . --config-file .checkov.yml` — 0 failures
3. `pytest -xvvs tests/` — integration test passes
4. `terraform plan` on a test config with `regions = ["us-east-1"]`
   — no errors
