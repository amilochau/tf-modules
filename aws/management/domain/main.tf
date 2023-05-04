resource "aws_route53_zone" "route53_zone" {
  name          = var.domain_settings.domain_name
  comment       = var.domain_settings.domain_description
  force_destroy = var.conventions.temporary
}

resource "aws_route53_record" "records" {
  for_each = var.domain_settings.records

  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "${each.key}.${var.domain_settings.domain_name}"
  type    = each.value.type
  ttl     = each.value.ttl_seconds
  records = each.value.records
}
