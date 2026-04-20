data "archive_file" "zip" {
  type        = "zip"
  source_file = "lambda/lambda_function.py"
  output_path = "lambda/lambda_function.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "rds-writer"

  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.10"
  role    = aws_iam_role.lambda_role.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group]
  }

  environment {
    variables = {
      DB_USER        = var.db_user
      DB_PASS        = var.db_pass
      DB_NAME        = var.db_name
      RDS_PROXY_HOST = var.proxy_endpoint
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

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