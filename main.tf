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
    "us-east-1"      = 127311923021
    "us-east-2"      = 033677994240
    "us-west-1"      = 027434742980
    "us-west-2"      = 797873946194
    "af-south-1"     = 098369216593
    "ap-east-1"      = 754344448648
    "ap-southeast-3" = 589379963580
    "ap-south-1"     = 718504428378
    "ap-northeast-3" = 383597477331
    "ap-northeast-2" = 600734575887
    "ap-southeast-1" = 114774131450
    "ap-southeast-2" = 783225319266
    "ap-northeast-1" = 582318560864
    "ca-central-1"   = 985666609251
    "eu-central-1"   = 054676820928
    "eu-west-1"      = 156460612806
    "eu-west-2"      = 652711504416
    "eu-south-1"     = 635631232127
    "eu-west-3"      = 009996457667
    "eu-north-1"     = 897822967062
    "me-south-1"     = 076674570225
    "sa-east-1"      = 507241528517
    "us-gov-west-1"  = 048591011584
    "us-gov-east-1"  = 190560391635
  }
}

module "flow_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  bucket_prefix = "${var.organization}-speedyway-vpc-flow-logs"

  tags = local.tags
}

resource "aws_s3_bucket_policy" "flow_logs_bucket" {
  bucket = module.flow_logs_bucket.s3_bucket_id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AWSLogDeliveryWrite",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "${module.flow_logs_bucket.s3_bucket_arn}/AWSLogs/*",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : data.aws_caller_identity.this.account_id,
            "s3:x-amz-acl" : "bucket-owner-full-control"
          },
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:logs:${var.region}:${local.account-id}:*"
          }
        }
      },
      {
        "Sid" : "AWSLogDeliveryAclCheck",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:GetBucketAcl",
        "Resource" : module.flow_logs_bucket.s3_bucket_arn,
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : data.aws_caller_identity.this.account_id
          },
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:logs:${var.region}:${local.account-id}:*"
          }
        }
      }
    ]
  })
}

module "alb_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  bucket_prefix = "${var.organization}-speedyway-alb-logs"

  tags = local.tags
}

resource "aws_s3_bucket_policy" "alb_logs_bucket" {
  bucket = module.alb_logs_bucket.s3_bucket_id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : (
          contains(keys(local.aws-elb-account-ids-by-region), var.region)
          ? { AWS = "arn:aws:iam::${local.aws-elb-account-ids-by-region[var.region]}:root" }
          : { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
        ),
        "Action" : "s3:PutObject",
        "Resource" : "${module.alb_logs_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.organization
  cidr = var.vpc-cidr-block

  azs             = local.azs
  private_subnets = local.private-subnets
  public_subnets  = local.public-subnets

  enable_nat_gateway = true
  single_nat_gateway = var.single-nat-gateway

  enable_flow_log                     = true
  flow_log_file_format                = "parquet"
  flow_log_destination_type           = "s3"
  flow_log_destination_arn            = module.flow_logs_bucket.s3_bucket_arn
  flow_log_hive_compatible_partitions = true

  tags = local.tags
}

resource "aws_security_group" "public_alb" {
  name_prefix = "${var.organization}-speedy-public-alb"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
}

resource "aws_security_group" "private_alb" {
  name_prefix = "${var.organization}-speedy-private-alb"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }
}

module "public-alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  depends_on = [aws_s3_bucket_policy.alb_logs_bucket]

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
}

module "private-alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  depends_on = [aws_s3_bucket_policy.alb_logs_bucket]

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
}
