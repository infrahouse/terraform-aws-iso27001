locals {
  module_version = "1.0.1"

  default_module_tags = merge(
    {
      created_by_module : "infrahouse/iso27001/aws"
    },
  )
}
