output "distribution_domains" {
  description = "Map of CloudFront distribution names to their domain names"
  value = {
    for dist_name, dist in aws_cloudfront_distribution.distributions : dist_name => dist.domain_name
  }
}

output "distribution_arns" {
  description = "Map of CloudFront distribution names to their ARNs"
  value = {
    for dist_name, dist in aws_cloudfront_distribution.distributions : dist_name => dist.arn
  }
}