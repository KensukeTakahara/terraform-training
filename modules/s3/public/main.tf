resource "aws_s3_bucket" "public" {
  bucket = var.bucket_name
  acl    = "public-read"

  cors_rule {
    allowed_origins = var.origins
    allowed_methods = var.methods
    allowed_headers = var.headers
    max_age_seconds = 3000
  }
}
