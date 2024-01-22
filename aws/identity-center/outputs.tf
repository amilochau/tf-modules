output "github_identity_provider_arn" {
  description = "ARN of the GitHub Identity provider"
  value = aws_iam_openid_connect_provider.github_identity_provider.arn
}