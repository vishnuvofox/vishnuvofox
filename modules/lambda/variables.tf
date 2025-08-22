variable "lambda_functions" {
  type        = map(object({
    description           = string
    runtime               = string
    memory_size           = number
    timeout               = number
    handler               = string
    filename              = string
    role                  = string
    environment_variables = map(string)
  }))
  description = "Map of Lambda function configurations"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the security group"
}

#variable "lambda_subnet_ids" {
#  type        = list(string)
#  description = "Private subnet IDs to attach Lambda to"
#}

#variable "lambda_sg_id" {
#  type        = string
#  description = "Security group ID for Lambda function"
#}
