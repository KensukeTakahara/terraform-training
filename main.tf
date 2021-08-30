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

module "network" {
  source = "./modules/network"
}

module "http_sg" {
  source      = "./modules/security_group"
  name        = "http-sg"
  vpc_id      = module.network.vpc_id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./modules/security_group"
  name        = "https-sg"
  vpc_id      = module.network.vpc_id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./modules/security_group"
  name        = "http-redirect-sg"
  vpc_id      = module.network.vpc_id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

module "example_alb" {
  source        = "./modules/alb"
  subnet_ids    = module.network.public_subnet_ids
  log_bucket_id = module.s3_bucket_log.id
  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}
