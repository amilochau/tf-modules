output "cloudfront_distribution_domain_name" {
  description = "The domain name of the deployed CloudFront distribution"
  value = module.cloudfront_distribution.cloudfront_distribution_domain_name
}
