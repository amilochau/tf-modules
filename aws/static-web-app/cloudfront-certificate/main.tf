terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.37, < 6.0.0"
      configuration_aliases = [
        aws.infrastructure,
        aws.workloads-us-east
      ]
    }
  }

  required_version = ">= 1.7.3, < 2.0.0"
}

data "aws_route53_zone" "route53_zone" {
  name = var.certificate_settings.zone_name

  provider = aws.infrastructure
}

resource "aws_acm_certificate" "acm_certificate" {
  domain_name               = var.certificate_settings.domain_name
  subject_alternative_names = var.certificate_settings.subject_alternative_names
  validation_method         = "DNS"

  provider = aws.workloads-us-east
}

resource "aws_route53_record" "route53_record" {
  for_each = { for v in aws_acm_certificate.acm_certificate.domain_validation_options : v.domain_name => v }

  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 60
  records = [each.value.resource_record_value]

  provider = aws.infrastructure
}

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_record : record.fqdn]

  provider = aws.workloads-us-east
}
