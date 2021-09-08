resource "aws_s3_bucket" "artifact" {
  bucket        = var.bucket_name
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}
