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
