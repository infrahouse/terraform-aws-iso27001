locals {
  module_version = "2.0.0"

  default_module_tags = merge(
    {
      created_by_module : "infrahouse/iso27001/aws"
    },
  )

  controltower_vpcs = merge([
    for region, vpcs in data.aws_vpcs.aws_control_tower_vpc : {
      for vpc_id in vpcs.ids : "${region}/${vpc_id}" => {
        region = region
        vpc_id = vpc_id
      }
    }
  ]...)
}
