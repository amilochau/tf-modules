terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

resource "aws_route53_zone" "route53_zone" {
  name          = var.domain_settings.domain_name
  comment       = var.domain_settings.domain_description
  force_destroy = var.context.temporary
}

resource "aws_route53_record" "records" {
  for_each = var.domain_settings.records

  zone_id = aws_route53_zone.route53_zone.zone_id
  name    = "${each.key}.${var.domain_settings.domain_name}"
  type    = each.value.type
  ttl     = each.value.ttl_seconds
  records = each.value.records
}
