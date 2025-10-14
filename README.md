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

## Usage

```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws
  version = "1.2.1"

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
