resource "aws_route53_zone" "route53_zone" {
  name = var.domain_settings.domain_name
  comment = var.domain_settings.domain_description
  force_destroy = var.conventions.temporary
}
