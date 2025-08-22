resource "aws_lambda_function" "this" {
  for_each = var.lambda_functions

  function_name = each.key
  description   = each.value.description
  runtime       = each.value.runtime
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout
  handler       = each.value.handler
  filename      = "${path.module}/${each.value.filename}"
  role          = each.value.role
#  vpc_config {
#    subnet_ids         = var.lambda_subnet_ids
#    security_group_ids = [var.lambda_sg_id]
#  }
  environment {
    variables = each.value.environment_variables
  }

  source_code_hash = filebase64sha256("${path.module}/${each.value.filename}")
}

