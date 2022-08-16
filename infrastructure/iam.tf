resource "aws_iam_role" "glue_job_role" {
  name               = "glue_job_role"
  path               = "/"
  description        = "S3 full access and CloudWatch Logs write permissions"
  tags               = local.common_tags
  assume_role_policy = file("./permissions/Role_GlueJob.json")
}

resource "aws_iam_policy" "glue_job_policy" {
  name        = "glue_job_policy"
  path        = "/"
  description = "Policy for AWS Glue service role which allows access to related services including EC2, S3, and Cloudwatch Logs"
  tags        = local.common_tags
  policy      = file("./permissions/Policy_GlueJob.json")
}

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = aws_iam_policy.glue_job_policy.arn
}

resource "aws_iam_role" "lambda_ans_etl" {
  name               = "${local.prefix}_Role_Lambda_Ans_ETL_S3"
  path               = "/"
  description        = "Provides write permissions to CloudWatch Logs and S3 Full Access"
  assume_role_policy = file("./permissions/Role_Lambda_Ans_ETL_S3.json")
}

resource "aws_iam_policy" "lambda_ans_etl" {
  name        = "${local.prefix}_Policy_Lambda_Ans_ETL_S3"
  path        = "/"
  description = "Provides write permissions to CloudWatch Logs and S3 Full Access"
  policy      = file("./permissions/Policy_Lambda_Ans_ETL_S3.json")
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_ans_etl.name
  policy_arn = aws_iam_policy.lambda_ans_etl.arn
}