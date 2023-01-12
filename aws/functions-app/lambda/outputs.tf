output "invoke_arn" {
  description = "ARN of the Invoke endpoint of the created function"
  value = aws_lambda_function.lambda_function.invoke_arn
}

output "function_name" {
  description = "Name of the created function"
  value = aws_lambda_function.lambda_function.function_name
}
