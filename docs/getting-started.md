# Getting Started

## Prerequisites

- Terraform >= 1.5
- AWS provider >= 6.0, < 7.0
- AWS account that is part of an AWS Organization
- IAM permissions to manage account-level resources (contacts, password policy,
  GuardDuty, IAM roles, S3 account settings, EBS defaults, Access Analyzer)

## First Deployment

### 1. Add the module to your configuration

```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version = "2.0.1"

  regions = ["us-east-1", "us-west-2"]

  primary_contact = {
    address_line_1  = "123 Any Street"
    city            = "Seattle"
    company_name    = "Your Company"
    country_code    = "US"
    full_name       = "Your Name"
    phone_number    = "+1234567890"
    postal_code     = "98101"
    state_or_region = "WA"
  }
  security_contact = {
    full_name    = "Security Team"
    title        = "Security Officer"
    email        = "security@yourcompany.com"
    phone_number = "+1234567890"
  }
}
```

### 2. Initialize and apply

```shell
terraform init
terraform plan
terraform apply
```

### 3. Confirm GuardDuty email subscription

After applying, check the security contact email for an SNS subscription
confirmation from each region. Confirm it to receive GuardDuty findings.

## Multi-Account Setup

In an AWS Organization, deploy this module in each member account. The module
creates an `InfraHouseLogRetention` IAM role that trusts the management account,
enabling centralized log retention enforcement via
[terraform-aws-org-governance](https://github.com/infrahouse/terraform-aws-org-governance).
