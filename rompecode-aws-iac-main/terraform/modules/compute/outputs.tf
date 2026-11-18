output "alb_dns_name" {
  description = "DNS público del ALB (usar esta URL en la demo)"
  value       = aws_lb.app.dns_name
}

output "alb_arn" {
  value = aws_lb.app.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2_sg.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}
