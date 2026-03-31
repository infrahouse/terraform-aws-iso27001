# terraform-aws-iso27001

A Terraform module that configures AWS account security controls and monitoring services to support ISO 27001 compliance requirements.

## Features

This module automatically configures the following security controls:

- **Account Contacts**: Sets up primary and security contact information
- **GuardDuty**: Enables threat detection across your AWS account
- **IAM Access Analyzer**: Monitors external access to your resources
- **Password Policy**: Enforces strong IAM password requirements
- **EBS Encryption**: Enables encryption by default for all EBS volumes
- **S3 Public Access Block**: Prevents public access to S3 buckets at the account level
- **VPC Security**: Configures default security groups to deny all traffic

Supports AWS provider versions ~> 5.62 and ~> 6.0

## Upgrading to 2.0.0

Version 2.0.0 removes the `AWSControlTowerExecution` IAM role and its `AdministratorAccess`
policy attachment from this module. This role is managed by AWS Control Tower itself
(created automatically during account enrollment) and should not be managed by Terraform.

Before upgrading, remove these resources from your Terraform state to avoid destroying
the role in AWS. Run the following commands for each root module that deploys `iso27001`
in `us-east-1`:

```shell
# Adjust the module path to match your configuration.
# For example, if your module is named "iso27001_us_east_1":
terraform state rm 'module.iso27001_us_east_1.aws_iam_role_policy_attachment.AdministratorAccess[0]'
terraform state rm 'module.iso27001_us_east_1.aws_iam_role.AWSControlTowerExecution[0]'
```

Only the `us-east-1` instance has these resources (they are conditional on the region).
Non-`us-east-1` instances require no action.

This version also adds the `InfraHouseLogRetention` IAM role, a least-privilege role
for cross-account CloudWatch log retention enforcement.

## Usage

```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws
  version = "1.3.0"

  primary_contact = {
    address_line_1     = "123 Any Street"
    city               = "Seattle"
    company_name       = "Example Corp, Inc."
    country_code       = "US"
    district_or_county = "King"
    full_name          = "My Name"
    phone_number       = "+64211111111"
    postal_code        = "98101"
    state_or_region    = "WA"
    website_url        = "https://www.examplecorp.com"
  }
  security_contact = {
    full_name    = "Security Team"
    title        = "Security Officer"
    email        = "security@example.com"
    phone_number = "+1234567890"
  }
}
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.11, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.11, < 7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_guardduty"></a> [guardduty](#module\_guardduty) | registry.infrahouse.com/infrahouse/guardduty-configuration/aws | 0.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_accessanalyzer_analyzer.external_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/accessanalyzer_analyzer) | resource |
| [aws_account_alternate_contact.security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_primary_contact.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_primary_contact) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_ebs_encryption_by_default.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_encryption_by_default) | resource |
| [aws_iam_account_password_policy.strict](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |
| [aws_s3_account_public_access_block.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_account_public_access_block) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpcs.aws-control-tower-VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_primary_contact"></a> [primary\_contact](#input\_primary\_contact) | Primary contact for the account. | <pre>object(<br/>    {<br/>      address_line_1     = string<br/>      address_line_2     = optional(string, null)<br/>      address_line_3     = optional(string, null)<br/>      city               = string<br/>      company_name       = string<br/>      country_code       = string<br/>      district_or_county = optional(string, null)<br/>      full_name          = string<br/>      phone_number       = string<br/>      postal_code        = string<br/>      state_or_region    = optional(string, null)<br/>      website_url        = optional(string, null)<br/>    }<br/>  )</pre> | n/a | yes |
| <a name="input_security_contact"></a> [security\_contact](#input\_security\_contact) | Security contact for the account. | <pre>object(<br/>    {<br/>      full_name    = string<br/>      phone_number = string<br/>      title        = string<br/>      email        = string<br/>    }<br/>  )</pre> | n/a | yes |

## Outputs

No outputs.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_accessanalyzer_analyzer.external_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/accessanalyzer_analyzer) | resource |
| [aws_account_alternate_contact.security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_primary_contact.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_primary_contact) | resource |
| [aws_cloudwatch_event_rule.guardduty_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.guardduty_notify](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_ebs_encryption_by_default.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_encryption_by_default) | resource |
| [aws_guardduty_detector.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_detector_feature.enabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.runtime_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_iam_account_password_policy.strict](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |
| [aws_iam_policy.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.InfraHouseLogRetention](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.InfraHouseLogRetention](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_account_public_access_block.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_account_public_access_block) | resource |
| [aws_sns_topic.guardduty_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.guardduty_emails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_iam_policy_document.InfraHouseLogRetention-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.InfraHouseLogRetention-trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.guardduty_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.guardduty_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_vpcs.aws_control_tower_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_primary_contact"></a> [primary\_contact](#input\_primary\_contact) | Primary contact for the account. | <pre>object(<br/>    {<br/>      address_line_1     = string<br/>      address_line_2     = optional(string, null)<br/>      address_line_3     = optional(string, null)<br/>      city               = string<br/>      company_name       = string<br/>      country_code       = string<br/>      district_or_county = optional(string, null)<br/>      full_name          = string<br/>      phone_number       = string<br/>      postal_code        = string<br/>      state_or_region    = optional(string, null)<br/>      website_url        = optional(string, null)<br/>    }<br/>  )</pre> | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | List of AWS regions to configure regional ISO 27001 controls in. | `list(string)` | n/a | yes |
| <a name="input_security_contact"></a> [security\_contact](#input\_security\_contact) | Security contact for the account. | <pre>object(<br/>    {<br/>      full_name    = string<br/>      phone_number = string<br/>      title        = string<br/>      email        = string<br/>    }<br/>  )</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
