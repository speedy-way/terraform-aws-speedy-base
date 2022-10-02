locals {
  azs = [
    for suffix in slice(var.availability-zones-pool, 0, var.number-of-availability-zones + 1) :
    "${var.region}-${suffix}"
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
}

module "flow_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  bucket_prefix = "${var.organization}-speedyway-vpc-flow-logs"
  vpc_id        = module.vpc.vpc_id

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
  vpc_id        = module.vpc.vpc_id

  tags = local.tags
}

resource "aws_s3_bucket_policy" "alb_logs_bucket" {
  bucket = module.alb_logs_bucket.s3_bucket_id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${local.account-id}:root"
        },
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

  name = "${var.organization}-speedyway-public"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = local.public-subnets
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

  name = "${var.organization}-speedyway-private"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = local.private-subnets
  security_groups = [aws_security_group.private_alb.id]

  access_logs = {
    bucket = module.alb_logs_bucket.s3_bucket_id
    prefix = "private"
  }

  tags = local.tags
}
