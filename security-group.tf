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
