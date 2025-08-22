output "queue_urls" {
  description = "Map of SQS queue names to their URLs"
  value = merge(
    { for name, queue in aws_sqs_queue.main_queues : name => queue.url },
    { for name, queue in aws_sqs_queue.dlq_queues : name => queue.url }
  )
}