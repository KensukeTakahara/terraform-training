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
  source        = "./modules/alb/main"
  subnet_ids    = module.network.public_subnet_ids
  log_bucket_id = module.s3_bucket_log.id
  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

module "route53_record" {
  source       = "./modules/route53_record"
  domain_name  = var.domain_name
  alb_dns_name = module.example_alb.alb_dns_name
  alb_zone_id  = module.example_alb.alb_zone_id
}

resource "aws_lb_target_group" "example" {
  name                 = "example"
  target_type          = "ip"
  vpc_id               = module.network.vpc_id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [
    module.example_alb
  ]
}

module "example_alb_listner" {
  source              = "./modules/alb/listner"
  alb_arn             = module.example_alb.alb_arn
  acm_certificate_arn = module.route53_record.certificate_arn
  target_group_arn    = aws_lb_target_group.example.arn
}
