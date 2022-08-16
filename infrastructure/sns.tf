resource "aws_sns_topic" "glue_job_ends" {
  name         = var.sns_name
  display_name = "Glue Job Ends"
}

resource "aws_sns_topic_policy" "glue_job_ends_policy" {
  arn    = aws_sns_topic.glue_job_ends.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.glue_job_ends.arn]
  }
}

resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.glue_job_ends.arn
  protocol  = "email"
  endpoint  = "matheuskraisfeld@gmail.com"
}

resource "aws_sns_topic_subscription" "glue_job_ends_sqs_target" {
  topic_arn = aws_sns_topic.glue_job_ends.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.glue_job_ends_queue.arn
}