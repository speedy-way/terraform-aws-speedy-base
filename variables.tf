variable "organization" {
  description = "Name of the base infrastructure organization. Usually the company name or group of products."
  type        = string
}

variable "region" {
  description = "AWS Region where the infrastrcuture will be provisioned."
  default     = "us-east-2"
  type        = string
}

variable "number-of-availability-zones" {
  description = "Number of availability zones to use to provision the infrastructure. Use for high availabily. May incur extra costs when provisioning compute capacity."
  default     = 2
  type        = number
}

variable "availability-zones-pool" {
  description = "Which availability zone letters to use as suffixes for the availability zones"
  default     = ["a", "b", "c"]
  type        = list(string)
}

variable "vpc-cidr-block" {
  default     = "10.0.0.0/16"
  description = "VPC CIDR Block. Must be within a 16 bit mask"
  type        = string
}

variable "single-nat-gateway" {
  default     = true
  description = "Single NAT gateway for all private subnets. Disable if hitting NAT gateway bottleneck. Incur extra costs."
  type        = bool
}
