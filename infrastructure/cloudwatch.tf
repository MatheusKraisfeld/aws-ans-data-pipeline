resource "aws_cloudwatch_event_rule" "glue_job_state_change" {
  name        = "glue_job_state_change"
  description = "CloudWatch Event Rule to trigger when a Glue Job changes state"

  event_pattern = <<EOF
{
    "source": [
        "aws.glue"
    ],
    "detail-type":[
        "Glue Job State Change"
    ],
    "detail": {
        "state": [
            "SUCCEEDED",
            "FAILED",
            "STOPPED",
            "TIMEOUT"
        ]
    }
}
EOF
}

resource "aws_cloudwatch_event_target" "sns_glue_job_ends" {
  rule      = aws_cloudwatch_event_rule.glue_job_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.glue_job_ends.arn
}