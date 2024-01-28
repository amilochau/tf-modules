output "lambda_function_arn" {
  description = "Lambda function ARN for the 'get' function"
  value       = module.functions_app.lambda_functions.get.lambda_function_arn
}
