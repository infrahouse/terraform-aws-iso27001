module "iso27001" {
  source = "./../../"
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
    name          = "Example"
    title         = "Example"
    email_address = "test@example.com"
    phone_number  = "+1234567890"
  }
}
