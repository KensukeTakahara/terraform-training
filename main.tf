module "describe_regions_for_ec2" {
  source     = "./modules/iam_role"
  name       = "describe-region-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}

module "s3_bucket_private" {
  source      = "./modules/s3/private"
  bucket_name = "kensuke-takahara-terraform-training-private-bucket"
}

module "s3_bucket_public" {
  source      = "./modules/s3/public"
  bucket_name = "kensuke-takahara-terraform-training-public-bucket"
  origins     = ["https://example.com"]
  methods     = ["GET"]
  headers     = ["*"]
}

module "s3_bucket_log" {
  source      = "./modules/s3/log"
  bucket_name = "kensuke-takahara-terraform-training-log-bucket"
}
