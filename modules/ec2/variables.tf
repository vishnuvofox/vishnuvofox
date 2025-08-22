variable "ami" {
  type        = string
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the EC2 instance"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for the EC2 instance"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile name for the EC2 instance"
}

variable "environment" {
  type        = string
  description = "Environment name for resource naming"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the security group"
}
variable "rds_endpoint" {
  type        = string
  description = "Endpoint for the RDS database"
}

variable "rds_port" {
  type        = number
  description = "Port for the RDS database"
}

variable "rds_db_name" {
  type        = string
  description = "Name of the RDS database"
}

variable "rds_password" {
  type        = string
  sensitive = true
}
variable "rds_username" {
  type        = string
  description = "Username for the RDS database"
}