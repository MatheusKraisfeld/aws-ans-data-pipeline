resource "aws_glue_catalog_database" "ans_cleaned_zone" {
  name = "ans_cleaned_zone"
}

resource "aws_glue_crawler" "cleaned_info_cons_ben" {
  database_name = aws_glue_catalog_database.ans_cleaned_zone.name
  name          = "info_cons_ben_cleaned_zone"
  role          = aws_iam_role.glue_job_role.arn

  s3_target {
    path = "${var.zone_bucket_paths[1]}/INFO_CONS_BEN/" # s3://ans-data-pipeline-cleaned-zone-741358071637/INFO_CONS_BEN/
  }

  tags = local.common_tags
}