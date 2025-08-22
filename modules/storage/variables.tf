variable "s3_buckets" {
  description = "Map of S3 bucket configurations"
  type = map(object({
    name        = string
    policy_type = string
  }))
}

variable "cloudfront_distribution_arns" {
  description = "Map of CloudFront distribution ARNs for buckets with policy_type = cloudfront"
  type        = map(string)
  default     = {}
}

