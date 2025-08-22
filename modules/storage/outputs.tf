output "buckets" {
  description = "Map of S3 buckets with their attributes"
  value = {
    for k, v in aws_s3_bucket.buckets : k => {
      bucket                    = v.id
      bucket_regional_domain_name = v.bucket_regional_domain_name
      arn                       = v.arn
    }
  }
}