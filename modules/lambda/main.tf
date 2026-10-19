data "aws_region" "current" {}

data "archive_file" "create" {
  type        = "zip"
  source_file = "${path.module}/../../src/createlambda.py"
  output_path = "${path.module}/create.zip"
}

data "archive_file" "retrieve" {
  type        = "zip"
  source_file = "${path.module}/../../src/retrievelambda.py"
  output_path = "${path.module}/retrieve.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.group_number}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ 
    Action = "sts:AssumeRole" 
    Effect = "Allow"
    Principal = { 
      Service = "lambda.amazonaws.com"
       }
     }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.group_number}-lambda-least-privilege"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"], Resource = var.table_arn },
      { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "arn:aws:logs:*:*:*" },
      { Effect = "Allow", Action = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "create" {
  filename         = data.archive_file.create.output_path
  source_code_hash = data.archive_file.create.output_base64sha256
  # Required to ensure Cloudwatch Logs Group initialization works cleanly 
  depends_on       = [aws_iam_role_policy_attachment.attach]
  function_name    = "${var.group_number}-create-url"
  role             = aws_iam_role.lambda_role.arn
  handler          = "createlambda.lambda_handler"
  runtime          = "python3.11"
  tracing_config   { mode = "Active" }

  environment {
    variables = {
      APP_URL    = "https://${var.domain_name}/"
      MIN_CHAR   = "12"
      MAX_CHAR   = "16"
      REGION_AWS = data.aws_region.current.name
      DB_NAME    = var.table_name
    }
  }
}

resource "aws_lambda_function" "retrieve" {
  filename         = data.archive_file.retrieve.output_path
  source_code_hash = data.archive_file.retrieve.output_base64sha256
  depends_on       = [aws_iam_role_policy_attachment.attach]
  function_name    = "${var.group_number}-retrieve-url"
  role             = aws_iam_role.lambda_role.arn
  handler          = "retrievelambda.lambda_handler"
  runtime          = "python3.11"
  tracing_config   { mode = "Active" }

  environment {
    variables = {
      REGION_AWS = data.aws_region.current.name
      DB_NAME    = var.table_name
    }
  }
}
