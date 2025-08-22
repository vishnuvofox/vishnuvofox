variable "identifier" {
  type        = string
  description = "Identifier for the RDS instance"
}

variable "engine_version" {
  type        = string
  description = "Database engine version"
  default     = "16.8"
}

variable "instance_class" {
  type        = string
  description = "Instance class for the RDS instance"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage for the RDS instance"
}

variable "rds_db_name" {
  type        = string
  description = "Name of the RDS database"
}

variable "username" {
  type        = string
  description = "Username for the database"
}

variable "password" {
  type        = string
  description = "Password for the database"
}

variable "db_password" {
  type        = string
  description = "Alias for the database password"
}

variable "multi_az" {
  type        = bool
  description = "Enable multi-AZ deployment"
  default     = false
}

variable "db_subnet_group_name" {
  type        = string
  description = "Name of the DB subnet group"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "rds_sg_id" {
  type        = string
  description = "Security group ID to be attached to RDS"
}
