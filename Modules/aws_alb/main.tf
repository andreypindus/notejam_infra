resource "aws_security_group" "new_security_group" {
  name        = var.group_name
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "new_sg_rule" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_security_group_rule" "new_sg_rule_2" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_lb" "new_alb" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.new_security_group.id]
  subnets            = var.subnets
}

resource "aws_lb_target_group" "new_tg" {
  name     = var.tg_name
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "new_listener" {
  load_balancer_arn = aws_lb.new_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.new_tg.arn
  }
}