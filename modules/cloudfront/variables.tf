variable "distributions" {
  type = map(object({
    name                   = string
    s3_bucket              = string
    geo_restriction_type   = string
    geo_locations          = list(string)
    viewer_protocol_policy = string
    price_class            = string
    waf_enabled            = bool
  }))
  description = "Map of CloudFront distribution configurations"
}
