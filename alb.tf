module "public-alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  depends_on = [aws_s3_bucket_policy.alb_logs_bucket]
  count = (
    var.create-shared-albs == true
    ? 1
    : 0
  )

  name = "${var.organization}-speedyway-public"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.public_alb.id]

  access_logs = {
    bucket = module.alb_logs_bucket.s3_bucket_id
    prefix = "public"
  }

  tags = local.tags

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn
      action_type     = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not found"
        status_code  = "404"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
}

module "private-alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  depends_on = [aws_s3_bucket_policy.alb_logs_bucket]
  count = (
    var.create-shared-albs == true
    ? 1
    : 0
  )

  name = "${var.organization}-speedyway-private"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  security_groups = [aws_security_group.private_alb.id]

  access_logs = {
    bucket = module.alb_logs_bucket.s3_bucket_id
    prefix = "private"
  }

  tags = local.tags

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn
      action_type     = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not found"
        status_code  = "404"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
}
