variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, prod)"
}


