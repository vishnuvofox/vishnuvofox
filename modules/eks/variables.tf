variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public endpoint access for the EKS cluster"
  type        = bool
}

variable "cluster_endpoint_private_access" {
  description = "Enable private endpoint access for the EKS cluster"
  type        = bool
}

variable "eks_node_ami_type" {
  description = "AMI type for EKS node group"
  type        = string
}

variable "eks_node_instance_types" {
  description = "List of instance types for EKS node group"
  type        = list(string)
}

variable "eks_node_capacity_type" {
  description = "Capacity type for EKS node group (e.g., ON_DEMAND, SPOT)"
  type        = string
}

variable "eks_node_min_size" {
  description = "Minimum size of EKS node group"
  type        = number
}

variable "eks_node_max_size" {
  description = "Maximum size of EKS node group"
  type        = number
}

variable "eks_node_desired_size" {
  description = "Desired size of EKS node group"
  type        = number
}

variable "ebs_csi_addon_version" {
  description = "Version of the EBS CSI Driver add-on"
  type        = string
}

variable "devops_user_arn" {
  description = "ARN of the DevOps IAM user for cluster admin access"
  type        = string
}

variable "root_account_arn" {
  description = "ARN of the root account for cluster admin access"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "authentication_mode" {
  type        = string
  default     = "API_AND_CONFIG_MAP"
  description = "Authentication mode for the EKS cluster (API or API_AND_CONFIG_MAP)"
}

variable "aws_region" {
  description = "AWS region where the EKS cluster will be deployed"
  type        = string
}


variable "gitlab_pat" {
  description = "GitLab Personal Access Token for NiFi registry"
  type        = string
  sensitive   = true
}
