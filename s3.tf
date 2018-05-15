resource "aws_s3_bucket" "titus_log_bucket" {
  bucket        = "titus-log-bucket-terraform-example"
  force_destroy = true
}
