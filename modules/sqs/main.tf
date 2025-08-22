data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "dlq_queues" {
  for_each = {
    for config in var.queue_configs : config.name => config
    if config.is_dlq == true
  }

  name                        = each.value.name
  visibility_timeout_seconds  = 30
  message_retention_seconds   = 345600
  max_message_size            = 262144
  delay_seconds               = 0
  receive_wait_time_seconds   = 0
  sqs_managed_sse_enabled     = true

  tags = merge(var.common_tags, {
    Name = each.value.name
    Type = "DLQ"
  })
}
resource "aws_sqs_queue" "main_queues" {
  for_each = {
    for config in var.queue_configs : config.name => config
    if !(lookup(config, "is_dlq", false))
  }

  name                        = each.value.name
  visibility_timeout_seconds  = 30
  message_retention_seconds   = 345600
  max_message_size            = 262144
  delay_seconds               = 0
  receive_wait_time_seconds   = 0
  sqs_managed_sse_enabled     = true

  redrive_policy = lookup(each.value, "dlq_name", null) != null ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq_queues[each.value.dlq_name].arn
    maxReceiveCount     = each.value.max_receive_count
  }) : null

  tags = merge(var.common_tags, {
    Name = each.value.name
    Type = "Standard"
  })
}
resource "aws_sqs_queue_policy" "queues" {
  for_each = merge(
    aws_sqs_queue.main_queues,
    aws_sqs_queue.dlq_queues
  )

  queue_url = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "__owner_statement"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "SQS:*"
        Resource = each.value.arn
      }
    ]
  })
}
