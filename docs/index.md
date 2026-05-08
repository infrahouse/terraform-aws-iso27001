# terraform-aws-iso27001

A Terraform module that configures AWS account security controls and monitoring
services to support ISO 27001 compliance requirements.

## Architecture

![Architecture](assets/architecture.svg)

## Overview

This module applies essential security controls to an AWS account in a single
deployment. It uses the AWS provider v6 `region` argument to manage multi-region
controls without requiring provider aliases.

## Features

- **Account Contacts** -- primary and security contact information
- **GuardDuty** -- threat detection with all detector features, per region
- **IAM Access Analyzer** -- external access monitoring, per region
- **Password Policy** -- strong IAM password requirements (21 chars minimum)
- **EBS Encryption** -- encryption by default for all EBS volumes, per region
- **S3 Public Access Block** -- prevents public access at the account level
- **VPC Security** -- default security groups deny all traffic
- **Vanta Auditor Role** -- `vanta-auditor` IAM role for Vanta's compliance
  scanner, with `SecurityAudit` and Identity Store read permissions. The
  external ID is read from SSM parameter `/vanta/external_id` (distributed
  by the org-governance StackSet).
- **Governance Role** -- least-privilege `InfraHouseGovernance` IAM role
  for cross-account CloudWatch log retention enforcement, log-group tagging,
  and Lambda-function tagging (e.g. Vanta exclusion of Control Tower-managed
  resources). The legacy `InfraHouseLogRetention` role is also deployed and
  is **deprecated** -- it will be removed in the next major release. See
  [issue #29](https://github.com/infrahouse/terraform-aws-iso27001/issues/29)
  for the migration plan.

## Quick Start

```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version = "2.3.0"

  regions = ["us-east-1", "us-west-2"]

  primary_contact = {
    address_line_1  = "123 Any Street"
    city            = "Seattle"
    company_name    = "Example Corp, Inc."
    country_code    = "US"
    full_name       = "My Name"
    phone_number    = "+64211111111"
    postal_code     = "98101"
    state_or_region = "WA"
  }
  security_contact = {
    full_name    = "Security Team"
    title        = "Security Officer"
    email        = "security@example.com"
    phone_number = "+1234567890"
  }
}
```
