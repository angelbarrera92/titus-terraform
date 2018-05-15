resource "aws_s3_bucket" "titus_log_bucket" {
  bucket        = "${var.s3_log_bucket_name}"
  force_destroy = true
}
