output "certificate_arn" {
  description = "ARN of the deployed certificate"
  value =   aws_acm_certificate_validation.acm_certificate_validation.certificate_arn
}
