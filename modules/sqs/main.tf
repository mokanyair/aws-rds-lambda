resource "aws_sqs_queue" "queue" {
  name = "lambda-queue"
}

resource "aws_lambda_event_source_mapping" "trigger" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = var.lambda_arn
}