module "iso27001" {
  source = "../../"

  regions = ["us-east-1"]

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
