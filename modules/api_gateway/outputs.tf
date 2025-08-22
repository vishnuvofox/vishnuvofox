output "execution_arn" {
  value       = aws_api_gateway_rest_api.api.execution_arn
  description = "Execution ARN of the API Gateway"
}