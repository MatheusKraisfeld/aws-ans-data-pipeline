variable "aws_region" {
  default = "us-east-1"
}

variable "account" {
  default = "741358071637"
}

variable "project_name" {
  default = "ans-data-pipeline"
}

variable "prefix" {
  default     = "ans-data-pipeline"
  description = "Prefix to be added to resources names"
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
  common_tags = {
    Project      = "aws-ans-data-pipeline",
    ManagedBy    = "Matheus Kraisfeld"
    Owner        = "Matheus Kraisfeld"
    BusinessUnit = "Data"
    Billing      = "Infrastructure"
    Environment  = terraform.workspace
    UserEmail    = "matheuskraisfeld@gmail.com"
  }
}

variable "zone_bucket_names" {
  description = "Create S3 buckets with these names"
  type        = list(string)
  default = [
    "raw-zone",
    "cleaned-zone",
    "curated-zone",
    "logs"
  ]
}

variable "zone_bucket_paths" {
  description = "Paths to S3 bucket used by the crawler"
  type        = list(string)
  default = [
    "s3://ans-data-pipeline-raw-zone-741358071637",
    "s3://ans-data-pipeline-cleaned-zone-741358071637",
    "s3://ans-data-pipeline-curated-zone-741358071637",
    "s3://ans-data-pipeline-logs-741358071637"
  ]
}

variable "bucket_scripts" {
  description = "Scripts to be executed in the crawler"
  default     = "ans-data-pipeline-resources"
}

variable "emr_scripts" {
  description = "List of emr scripts to be uploaded"
  type        = list(string)
  default     = ["ans_crawler_info_cons_ben", "ans_cleaner_info_cons_ben"]
}

variable "glue_scripts" {
  description = "List of glue scripts to be uploaded"
  type        = list(string)
  default     = ["ans_crawler_info_cons_ben", "ans_cleaner_info_cons_ben"]
}

variable "glue_scripts_max_capacity" {
  description = "Max DPU capacity for each glue script"
  type        = list(number)
  default     = [2, 2]
}
