resource "aws_cloudfront_distribution" "distributions" {
  for_each = var.distributions

  origin {
    domain_name = each.value.s3_bucket
    origin_id   = "S3-${each.key}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac[each.key].id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = each.value.price_class

  default_cache_behavior {
    target_origin_id       = "S3-${each.key}"
    viewer_protocol_policy = each.value.viewer_protocol_policy
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS Managed CachingOptimized
    compress               = true
  }

  dynamic "custom_error_response" {
    for_each = each.key == "ui" ? [403, 404] : []
    content {
      error_code            = custom_error_response.value
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = each.value.geo_restriction_type
      locations        = each.value.geo_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = each.value.waf_enabled ? aws_wafv2_web_acl.cloudfront_waf[each.key].arn : null

  tags = {
    Name        = each.value.name
    Environment = "production"
    Project     = "FHIR"
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  for_each = var.distributions
  name     = "${each.value.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us_east_1
  for_each = { for k, v in var.distributions : k => v if v.waf_enabled }
  name        = "${each.value.name}-waf"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${each.value.name}-CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${each.value.name}-WAF"
    sampled_requests_enabled   = true
  }
}