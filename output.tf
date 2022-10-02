output "vpc" {
  value = module.vpc
}

output "public-load-balancer" {
  value = module.public-alb
}

output "private-load-balancer" {
  value = module.private-alb
}

output "public-alb-security-group" {
  value = aws_security_group.public_alb
}

output "private-alb-security-group" {
  value = aws_security_group.private_alb
}

output "vpc-flow-logs-bucket" {
  value = module.flow_logs_bucket
}

output "alb-logs-bucket" {
  value = module.alb_logs_bucket
}
