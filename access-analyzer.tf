resource "aws_accessanalyzer_analyzer" "external_access" {
  for_each      = toset(var.regions)
  analyzer_name = "external-access-analyzer"
  region        = each.key
}
