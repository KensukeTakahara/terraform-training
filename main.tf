locals {
  rds_port         = 3306
  elasticache_port = 6379
}

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

  depends_on = [module.route53_record]
}

module "nginx_sg" {
  source      = "./modules/security_group"
  name        = "nginx-sg"
  vpc_id      = module.network.vpc_id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "ecs_task_execution_role" {
  source     = "./modules/iam_role"
  name       = "ecs-task-excution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

module "example_nginx_ecs" {
  source             = "./modules/ecs/nginx"
  security_group_ids = [module.nginx_sg.security_group_id]
  private_subnet_ids = module.network.private_subnet_ids
  target_group_arn   = aws_lb_target_group.example.arn
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn

  depends_on = [module.example_alb_listner]
}

module "ecs_events_role" {
  source     = "./modules/iam_role"
  name       = "ecs-events"
  identifier = "events.amazonaws.com"
  policy     = data.aws_iam_policy.ecs_events_role_policy.policy
}

module "example_batch_ecs" {
  source             = "./modules/ecs/batch"
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
  event_role_arn     = module.ecs_events_role.iam_role_arn
  ecs_cluster_arn    = module.example_nginx_ecs.ecs_cluster_arn
  subnet_ids         = module.network.private_subnet_ids
}

resource "aws_kms_key" "example" {
  description             = "Example Customer Master Key"
  enable_key_rotation     = true
  is_enabled              = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "example" {
  name          = "alias/example"
  target_key_id = aws_kms_key.example.key_id
}

module "ssm_parameter_store_example" {
  source = "./modules/ssm/parameter_store"
}

module "mysql_sg" {
  source      = "./modules/security_group"
  name        = "mysql-sg"
  vpc_id      = module.network.vpc_id
  port        = local.rds_port
  cidr_blocks = [module.network.cidr_block]
}

module "rds" {
  source            = "./modules/rds"
  subnet_ids        = module.network.private_subnet_ids
  kms_key_id        = aws_kms_key.example.arn
  security_group_id = module.mysql_sg.security_group_id
  port              = local.rds_port
}

module "redis_sg" {
  source      = "./modules/security_group"
  name        = "redis-sg"
  vpc_id      = module.network.vpc_id
  port        = local.elasticache_port
  cidr_blocks = [module.network.cidr_block]
}

module "elasticache" {
  source            = "./modules/elasticache"
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.redis_sg.security_group_id
  port              = local.elasticache_port
}

module "ecr" {
  source = "./modules/ecr"
}

module "codebuild_role" {
  source     = "./modules/iam_role"
  name       = "codebuild"
  identifier = "codebuild.amazonaws.com"
  policy     = data.aws_iam_policy_document.codebuild.json
}

module "codebuild_example" {
  source           = "./modules/codebuild"
  service_role_arn = module.codebuild_role.iam_role_arn
}

module "codepipeline_role" {
  source     = "./modules/iam_role"
  name       = "codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

module "s3_bucket_artifact" {
  source      = "./modules/s3/artifact"
  bucket_name = "kensuke-takahara-terraform-training-artifact-bucket"
}

module "codepipeline_example" {
  source               = "./modules/codepipeline"
  role_arn             = module.codepipeline_role.iam_role_arn
  repository           = "KensukeTakahara/terraform-training"
  codebuild_project_id = module.codebuild_example.id
  ecs_cluster_name     = module.example_nginx_ecs.ecs_cluster_name
  ecs_service_name     = module.example_nginx_ecs.ecs_service_name
  artifact_bucket_id   = module.s3_bucket_artifact.id
}

module "s3_bucket_operation" {
  source      = "./modules/s3/artifact"
  bucket_name = "kensuke-takahara-terraform-training-operation-bucket"
}

module "ec2_for_ssm_role" {
  source     = "./modules/iam_role"
  name       = "ec2-for-ssm"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}

module "session_manager_example" {
  source              = "./modules/ssm/session_manager"
  iam_role_name       = module.ec2_for_ssm_role.iam_role_name
  private_subnet_id   = module.network.private_subnet_1a_id
  operation_bucket_id = module.s3_bucket_operation.id
}

module "s3_bucket_cloudwatch_logs" {
  source      = "./modules/s3/artifact"
  bucket_name = "kensuke-takahara-terraform-training-cloudwatch-logs-bucket"
}

module "kinesis_data_firehose_role" {
  source     = "./modules/iam_role"
  name       = "kinesis-data-firehose"
  identifier = "firehose.amazonaws.com"
  policy     = data.aws_iam_policy_document.kinesis_data_firehose.json
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example"
  destination = "s3"

  s3_configuration {
    role_arn   = module.kinesis_data_firehose_role.iam_role_arn
    bucket_arn = module.s3_bucket_cloudwatch_logs.arn
    prefix     = "ecs-scheduled-tasks/example"
  }
}
