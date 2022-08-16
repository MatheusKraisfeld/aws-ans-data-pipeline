resource "aws_s3_bucket" "buckets" {
  count  = length(var.zone_bucket_names)
  bucket = "${var.project_name}-${var.zone_bucket_names[count.index]}-${var.account}"
}

resource "aws_s3_bucket_acl" "buckets" {
  count  = length(var.zone_bucket_names)
  bucket = "${var.project_name}-${var.zone_bucket_names[count.index]}-${var.account}"
  acl    = "private"
}

resource "aws_kms_key" "mykey" {
  description = "This key is used to encrypt bucket objects"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_functions" {
  count  = length(var.zone_bucket_names)
  bucket = "${var.project_name}-${var.zone_bucket_names[count.index]}-${var.account}"
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "bucket_scripts" {
  bucket = "${var.bucket_scripts}-${var.account}"
}

resource "aws_s3_bucket_acl" "bucket_scripts" {
  bucket = "${var.bucket_scripts}-${var.account}"
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_scripts_function" {
  bucket = "${var.bucket_scripts}-${var.account}"
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}