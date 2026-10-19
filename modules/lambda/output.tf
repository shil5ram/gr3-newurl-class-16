output "create_invoke_arn"   { value = aws_lambda_function.create.invoke_arn }
output "retrieve_invoke_arn" { value = aws_lambda_function.retrieve.invoke_arn }
output "create_name"         { value = aws_lambda_function.create.function_name }
output "retrieve_name"       { value = aws_lambda_function.retrieve.function_name }
