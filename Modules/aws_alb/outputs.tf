output "alb_id" {
  value = aws_lb.new_alb.id
}

output "alb_arn" {
  value = aws_lb.new_alb.arn
}

output "group_id" {
  value = aws_security_group.new_security_group.id
}

output "alb_listener_id" {
  value = aws_lb_listener.new_listener.id
}

output "alb_listener_arn" {
  value = aws_lb_listener.new_listener.arn
}

output "alb_target_id" {
  value = aws_lb_target_group.new_tg.id
}