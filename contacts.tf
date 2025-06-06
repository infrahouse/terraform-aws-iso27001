resource "aws_account_primary_contact" "this" {
  count              = data.aws_region.current.name == "us-east-1" ? 1 : 0
  address_line_1     = var.primary_contact.address_line_1
  address_line_2     = var.primary_contact.address_line_2
  address_line_3     = var.primary_contact.address_line_3
  city               = var.primary_contact.city
  company_name       = var.primary_contact.company_name
  country_code       = var.primary_contact.country_code
  district_or_county = var.primary_contact.district_or_county
  full_name          = var.primary_contact.full_name
  phone_number       = var.primary_contact.phone_number
  postal_code        = var.primary_contact.postal_code
  state_or_region    = var.primary_contact.state_or_region
  website_url        = var.primary_contact.website_url
}

resource "aws_account_alternate_contact" "security" {
  count                  = data.aws_region.current.name == "us-east-1" ? 1 : 0
  alternate_contact_type = "SECURITY"
  title                  = var.security_contact.title
  name                   = var.security_contact.full_name
  phone_number           = var.security_contact.phone_number
  email_address          = var.security_contact.email
}
