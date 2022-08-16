resource "aws_glue_job" "glue_job" {
  count        = length(var.glue_scripts)
  name         = var.glue_scripts[count.index]
  role_arn     = aws_iam_role.glue_job_role.arn
  max_capacity = var.glue_scripts_max_capacity[count.index]
  glue_version = "3.0"
  command {
    script_location = "s3://ans-data-pipeline-resources-741358071637/.glue_scripts/${var.glue_scripts[count.index]}.py"
    python_version  = "3"
  }
  default_arguments = {
    "--additional-python-modules" = "pyarrow==2, awswrangler==2.7.0, XlsxWriter==1.4.4, Unidecode==1.3.2"
  }
  depends_on = [
    aws_s3_object.glue_script_s3_object,
  ]
  tags = local.common_tags
}

resource "aws_glue_trigger" "ans_crawler_info_cons_ben" {
  name     = "ans_crawler_info_cons_ben"
  schedule = "cron(24 16 16 * ? *)" # UTC Timezone
  type     = "SCHEDULED"

  actions {
    job_name = var.glue_scripts[0] # ans_crawler_info_cons_ben
  }
}

resource "aws_glue_trigger" "ans_cleaner_info_cons_ben" {
  name = "ans_cleaner_info_cons_ben"
  type = "CONDITIONAL"

  actions {
    job_name = var.glue_scripts[1] # ans_cleaner_info_cons_ben
  }

  predicate {
    conditions {
      job_name = var.glue_scripts[0] # ans_crawler_info_cons_ben
      state    = "SUCCEEDED"
    }
  }
}

resource "aws_glue_trigger" "ans_cleaner_info_cons_ben_crawler" {
  name = "ans_cleaner_info_cons_ben_crawler"
  type = "CONDITIONAL"

  actions {
    crawler_name = aws_glue_crawler.cleaned_info_cons_ben.name
  }

  predicate {
    conditions {
      job_name = var.glue_scripts[1] # ans_crawler_info_cons_ben
      state    = "SUCCEEDED"
    }
  }
}