# -------------------
# VPC
# -------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = ["us-east-1a", "us-east-1b"][count.index]
}

# -------------------
# Security Groups
# -------------------
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
}

# -------------------
# RDS
# -------------------
resource "aws_db_instance" "mysql" {
  identifier        = "lambda-rds-db"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "admin"
  password = "Password123!"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
}

resource "aws_db_subnet_group" "main" {
  subnet_ids = aws_subnet.private[*].id
}

# -------------------
# SQS
# -------------------
resource "aws_sqs_queue" "queue" {
  name = "lambda-rds-queue"
}

# -------------------
# IAM Role
# -------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda-rds-role"

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

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -------------------
# Lambda
# -------------------
resource "aws_lambda_function" "lambda" {
  function_name = "rds-writer"

  filename         = "lambda/lambda_function.zip"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  role             = aws_iam_role.lambda_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST = aws_db_instance.mysql.address
      DB_USER = "admin"
      DB_PASS = "Password123!"
      DB_NAME = "testdb"
    }
  }
}

# -------------------
# SQS Trigger
# -------------------
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = aws_lambda_function.lambda.arn
  batch_size       = 1
}