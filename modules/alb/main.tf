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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは[HTTP]です。"
      status_code  = "200"
    }
  }
}
