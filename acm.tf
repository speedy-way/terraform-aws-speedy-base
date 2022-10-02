module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = var.zone
  zone_id      = local.zone.id

  wait_for_validation = true

  tags = local.tags
}
