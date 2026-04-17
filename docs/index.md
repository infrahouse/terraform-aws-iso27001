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
- **Log Retention Role** -- least-privilege IAM role for cross-account
  CloudWatch log retention enforcement

## Quick Start

```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version = "2.1.0"

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
