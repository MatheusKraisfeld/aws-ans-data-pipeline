data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "functions/lambda_ans_etl/"
  output_path = "functions/lambda_ans_etl.zip"
}

resource "aws_lambda_function" "lambda_ans_etl" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.prefix}_lambda_ans_etl"
  role             = aws_iam_role.lambda_ans_etl.arn
  handler          = "handler.handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  runtime          = "python3.8"
  timeout          = 900
  memory_size      = 10000

  tags = local.common_tags

}

resource "aws_cloudwatch_log_group" "lambda_ans_etl" {
  name              = "/aws/lambda/${local.prefix}_lambda_ans_etl"
  retention_in_days = 30
}

# resource "aws_cloudwatch_event_rule" "every_fifteenth_day" {
#   name        = "every-fifteenth-day"
#   description = "Fires for every 15th day"
#   schedule_expression = "cron(0 0 15 * *)"
# }

# resource "aws_cloudwatch_event_target" "lambda_ans_etl_every_fifteenth_day" {
#   rule      = aws_cloudwatch_event_rule.every_fifteenth_day.name
#   target_id = "lambda_ans_etl"
#   arn       = aws_lambda_function.lambda_ans_etl.arn
# }

# resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_ans_etl" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_ans_etl.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.every_fifteenth_day.arn
# }