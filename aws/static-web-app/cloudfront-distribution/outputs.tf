output "cloudfront_distribution_domain_name" {
  description = "The domain name of the deployed CloudFront distribution"
  value = aws_cloudfront_distribution.cloudfront_distribution.domain_name
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the deployed CloudFront distribution"
  value = aws_cloudfront_distribution.cloudfront_distribution.arn
}
