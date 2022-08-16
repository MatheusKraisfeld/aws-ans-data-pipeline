resource "aws_sqs_queue" "glue_job_ends_queue" {
  name = var.glue_job_sqs_name
}

resource "aws_sqs_queue_policy" "glue_job_ends_queue_policy" {
  queue_url = aws_sqs_queue.glue_job_ends_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.glue_job_ends_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.glue_job_ends.arn}"
        }
      }
    }
  ]
}
POLICY
}