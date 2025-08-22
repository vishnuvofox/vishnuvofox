variable "pool_name" {
  type        = string
  description = "Name of the Cognito user pool"
}

variable "domain_prefix" {
  type        = string
  description = "Domain prefix for the Cognito user pool"
}

variable "app_client_name" {
  type        = string
  description = "Name of the Cognito user pool client"
}

variable "app_callback_urls" {
  type        = list(string)
  description = "Callback URLs for the Cognito user pool client"
}

variable "deletion_protection" {
  default = "INACTIVE"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the Cognito provider"
}