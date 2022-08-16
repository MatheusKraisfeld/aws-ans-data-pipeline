resource "aws_s3_object" "emr_script_s3_object" {
  count  = length(var.emr_scripts)
  bucket = "${var.bucket_scripts}-${var.account}"
  key    = "/.emr_scripts/${var.emr_scripts[count.index]}.py"
  source = "../etl/emr/${var.emr_scripts[count.index]}.py"
  etag   = filemd5("../etl/emr/${var.emr_scripts[count.index]}.py")
}

resource "aws_s3_object" "glue_script_s3_object" {
  count  = length(var.glue_scripts)
  bucket = "${var.bucket_scripts}-${var.account}"
  key    = "/.glue_scripts/${var.glue_scripts[count.index]}.py"
  source = "../etl/glue/${var.glue_scripts[count.index]}.py"
  etag   = filemd5("../etl/glue/${var.glue_scripts[count.index]}.py")
}

resource "aws_s3_object" "emr_bootstrap_s3_object" {
  bucket = "${var.bucket_scripts}-${var.account}"
  key    = "/.bootstrap_scripts/bootstrap_install.sh"
  source = "./scripts/bootstrap_install.sh"
  etag   = filemd5("./scripts/bootstrap_install.sh")
}