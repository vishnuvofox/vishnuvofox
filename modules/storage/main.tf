

resource "aws_s3_bucket" "buckets" {
  for_each = var.s3_buckets
  bucket   = each.value.name
  force_destroy = true # REMOVE THIS IN PRODUCTION
  tags     = { Name = each.value.name, Environment = "production", Project = "FHIR" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = aws_s3_bucket.buckets
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  for_each = { for k, v in var.s3_buckets : k => v if v.policy_type == "public" }
  bucket   = aws_s3_bucket.buckets[each.key].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "cloudfront_policy" {
  for_each = { for k, v in var.s3_buckets : k => v if v.policy_type == "cloudfront" && contains(keys(var.cloudfront_distribution_arns), k) }
  bucket   = aws_s3_bucket.buckets[each.key].id
  policy   = jsonencode({
    Version = "2008-10-17",
    Id      = "PolicyForCloudFrontPrivateContent",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal",
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.buckets[each.key].arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arns[each.key]
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "public_policy" {
  for_each = { for k, v in var.s3_buckets : k => v if v.policy_type == "public" }
  bucket   = aws_s3_bucket.buckets[each.key].id
  policy   = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource  = "${aws_s3_bucket.buckets[each.key].arn}/*"
      }
    ]
  })
}

resource "null_resource" "upload_ui_files" {
  provisioner "local-exec" {
    command = <<EOT
      aws s3 cp "${path.module}/fhir-ui" "s3://${var.s3_buckets["ui"].name}" --recursive
    EOT
    interpreter = ["powershell", "-Command"]
  }
  depends_on = [ aws_s3_bucket.buckets ]
}

resource "null_resource" "upload_blockly_files" {
  provisioner "local-exec" {
    command = <<EOT
      aws s3 cp "${path.module}/fhir-blockly" "s3://${var.s3_buckets["blockly"].name}" --recursive
    EOT
    interpreter = ["powershell", "-Command"]
  }
  depends_on = [ aws_s3_bucket.buckets ]
}

