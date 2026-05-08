module "iso27001" {
  source  = "./../../"
  regions = var.regions
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

output "governance_role_name" {
  value = module.iso27001.governance_role_name
}

output "governance_role_arn" {
  value = module.iso27001.governance_role_arn
}

output "vanta_auditor_role_name" {
  value = module.iso27001.vanta_auditor_role_name
}

output "vanta_auditor_role_arn" {
  value = module.iso27001.vanta_auditor_role_arn
}

output "log_retention_role_name" {
  value = module.iso27001.log_retention_role_name
}

output "log_retention_role_arn" {
  value = module.iso27001.log_retention_role_arn
}
