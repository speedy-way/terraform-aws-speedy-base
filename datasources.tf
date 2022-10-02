data "aws_caller_identity" "this" {}

data "aws_route53_zone" "this" {
  count = range(
    var.create-zone == true
    ? 0
    : 1
  )

  zone_id = var.zone
}