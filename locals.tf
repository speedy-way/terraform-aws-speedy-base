locals {
  azs = [
    for suffix in slice(var.availability-zones-pool, 0, var.number-of-availability-zones + 1) :
    "${var.region}${suffix}"
  ]
  public-subnets = [
    for netnum in range(0, var.number-of-availability-zones) :
    cidrsubnet(var.vpc-cidr-block, 8, netnum)
  ]
  private-subnets = [
    for netnum in range(var.number-of-availability-zones, var.number-of-availability-zones * 2) :
    cidrsubnet(var.vpc-cidr-block, 8, netnum)
  ]
  tags = {
    ManagedBy    = "Terraform"
    Environment  = "base"
    Organization = var.organization
    Context      = "SpeedyWay"
  }
  account-id = data.aws_caller_identity.this.account_id
  aws-elb-account-ids-by-region = {
    "us-east-1"      = "127311923021"
    "us-east-2"      = "033677994240"
    "us-west-1"      = "027434742980"
    "us-west-2"      = "797873946194"
    "af-south-1"     = "098369216593"
    "ap-east-1"      = "754344448648"
    "ap-southeast-3" = "589379963580"
    "ap-south-1"     = "718504428378"
    "ap-northeast-3" = "383597477331"
    "ap-northeast-2" = "600734575887"
    "ap-southeast-1" = "114774131450"
    "ap-southeast-2" = "783225319266"
    "ap-northeast-1" = "582318560864"
    "ca-central-1"   = "985666609251"
    "eu-central-1"   = "054676820928"
    "eu-west-1"      = "156460612806"
    "eu-west-2"      = "652711504416"
    "eu-south-1"     = "635631232127"
    "eu-west-3"      = "009996457667"
    "eu-north-1"     = "897822967062"
    "me-south-1"     = "076674570225"
    "sa-east-1"      = "507241528517"
    "us-gov-west-1"  = "048591011584"
    "us-gov-east-1"  = "190560391635"
  }
  zone = (
    var.create-zone == true
    ? aws_route53_zone.this[0]
    : data.aws_route53_zone.this[0]
  )
}
