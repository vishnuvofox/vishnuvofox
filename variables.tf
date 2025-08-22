variable "aws_access_key" {
  type        = string
  description = "AWS access key for authentication"

}
variable "aws_secret_key" {
  type        = string
  description = "AWS secret key for authentication"
  sensitive   = true

}

variable "environment" {
  type        = string
  description = "Environment name for resource naming (e.g., prod, dev)"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "ap-south-1"
}

variable "rds_password" {
  type        = string
  description = "Password for the RDS database"
  sensitive   = true
  default     = "faDSF43qtqegfqjkaa4#"
}

variable "db_password" {
  type        = string
  description = "Alias for the RDS database password"
  sensitive   = true
  default     = "faDSF43qtqegfqjkaa4#"
}

variable "rds_db_name" {
  type        = string
  description = "Name of the RDS database"
  default     = "FHIR"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "fhir-nifi-cluster"
}

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
}
variable "queue_configs" {
  description = "List of SQS queue configurations"
  type = list(object({
    name              = string
    is_dlq            = optional(bool)
    dlq_name          = optional(string)
    max_receive_count = optional(number)
  }))

  default = [
    {
      name              = "BLOCKLY-REQUEST-VALIDATE"
      is_dlq            = false
      dlq_name          = "BLOCKLY-DLQ"
      max_receive_count = 5
    },
    {
      name              = "BLOCKLY-RESPONSE-VALIDATE"
      is_dlq            = false
      dlq_name          = "BLOCKLY-DLQ"
      max_receive_count = 5
    },
    {
      name   = "BLOCKLY-DLQ"
      is_dlq = true
    },
    {
      name              = "BLOCKLY-TENANT-ID"
      is_dlq            = false
      dlq_name          = "BLOCKLY-TENANT-ID-DLQ"
      max_receive_count = 3
    },
    {
      name   = "BLOCKLY-TENANT-ID-DLQ"
      is_dlq = true
    }
  ]
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)

  default = {
    Environment = "dev"
    Project     = "FHIR"
  }
}

variable "gitlab_pat" {
  description = "GitLab Personal Access Token for NiFi registry"
  type        = string
  sensitive   = true
}


