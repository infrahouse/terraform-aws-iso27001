# terraform-aws-iso27001
Module enables and configures resources needed for ISO 27001 compliance

## Usage

```hcl
module "iso27001" {
    source  = "registry.infrahouse.com/infrahouse/iso27001/aws
    version = "0.1.0"

    configure_password_policy = true
    notification_email        = "nG2wG@example.com"
}
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.11 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.11 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_guardduty"></a> [guardduty](#module\_guardduty) | registry.infrahouse.com/infrahouse/guardduty-configuration/aws | 0.2.1 |

## Resources

| Name | Type |
|------|------|
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_iam_account_password_policy.strict](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |
| [aws_vpcs.aws-control-tower-VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configure_password_policy"></a> [configure\_password\_policy](#input\_configure\_password\_policy) | If true, the module will configure the password policy. | `bool` | `false` | no |
| <a name="input_notification_email"></a> [notification\_email](#input\_notification\_email) | Email address to send GuardDuty notifications to. | `any` | n/a | yes |

## Outputs

No outputs.
