variable "queue_configs" {
  description = "List of queue configurations"
  type = list(object({
    name              = string
    is_dlq            = optional(bool)
    dlq_name          = optional(string)
    max_receive_count = optional(number)
  }))
}

variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
}
