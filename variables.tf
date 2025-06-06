variable "primary_contact" {
  description = "Primary contact for the account."
  type = map(
    object(
      {
        address_line_1     = string
        address_line_2     = optional(string, null)
        address_line_3     = optional(string, null)
        city               = string
        company_name       = string
        country_code       = string
        district_or_county = optional(string, null)
        full_name          = string
        phone_number       = string
        postal_code        = string
        state_or_region    = optional(string, null)
        website_url        = optional(string, null)
      }
    )
  )
}

variable "security_contact" {
  description = "Security contact for the account."
  type = map(
    object(
      {
        full_name    = string
        phone_number = string
        title        = string
        email        = string
      }
    )
  )
}
