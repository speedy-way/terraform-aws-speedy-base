module "flow_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  bucket_prefix = "${var.organization}-speedyway-vpc-flow-logs"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

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

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

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
