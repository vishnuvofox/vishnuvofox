variable "rest_api_name" {
  type        = string
  description = "Name of the REST API"
}

variable "api_name" {
  type        = string
  description = "Name of the API Gateway"
}

variable "lambda_integration_uri" {
  type        = string
  description = "URI for Lambda function integration"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the API Gateway will be deployed"  
}