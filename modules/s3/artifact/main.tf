resource "aws_s3_bucket" "artifact" {
  bucket = var.bucket_name

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}
