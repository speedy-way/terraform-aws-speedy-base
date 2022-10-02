resource "aws_route53_zone" "this" {
  count = (
    var.create-zone == true
    ? 1
    : 0
  )

  name              = var.zone
  delegation_set_id = var.delegation-set-id

  tags = local.tags
}