# Examples

## Basic Single-Region

```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version = "2.1.0"

  regions = ["us-east-1"]

  primary_contact = {
    address_line_1  = "123 Any Street"
    city            = "Seattle"
    company_name    = "Example Corp"
    country_code    = "US"
    full_name       = "John Smith"
    phone_number    = "+1234567890"
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

## Multi-Region Production

```hcl
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version = "2.1.0"

  regions = [
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
  ]

  primary_contact = {
    address_line_1  = "123 Any Street"
    city            = "Seattle"
    company_name    = "Example Corp"
    country_code    = "US"
    full_name       = "John Smith"
    phone_number    = "+1234567890"
    postal_code     = "98101"
    state_or_region = "WA"
  }
  security_contact = {
    full_name    = "Security Team"
    title        = "CISO"
    email        = "security@example.com"
    phone_number = "+1234567890"
  }
}
```

## Multi-Account with org-governance

Deploy `iso27001` in each member account and `org-governance` in the
management account for centralized log retention enforcement:

```hcl
# In each member account
module "iso27001" {
  source  = "registry.infrahouse.com/infrahouse/iso27001/aws"
  version = "2.1.0"

  regions = ["us-east-1", "us-west-2"]

  primary_contact  = local.primary_contact
  security_contact = local.security_contact
}

# In the management account
module "org_governance" {
  source  = "registry.infrahouse.com/infrahouse/org-governance/aws"
  version = "~> 0.2"

  alarm_emails = ["ops@example.com"]
}
```
