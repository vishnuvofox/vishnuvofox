output "aws_lambda_function" {
  value = {
    for name, lambda in aws_lambda_function.this :
    name => {
      function_name = lambda.function_name
      invoke_arn    = lambda.invoke_arn
      arn           = lambda.arn
    }
  }
}
