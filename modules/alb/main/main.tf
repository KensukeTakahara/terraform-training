resource "aws_lb" "example" {
  name                       = "example"
  load_balancer_type         = "application"
  internal                   = false
  enable_deletion_protection = false

  subnets = var.subnet_ids

  access_logs {
    bucket  = var.log_bucket_id
    enabled = true
  }

  security_groups = var.security_groups
}
