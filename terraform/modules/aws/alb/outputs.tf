output "alb_arn" {
  description = "The ARN of the ALB"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.alb.dns_name
}

output "alb_security_group_id" {
  description = "The security group ID associated with the ALB"
  value       = module.alb.security_group_id
}

output "alb_target_group_arns" {
  description = "Map of ALB target group ARNs"
  value       = module.alb.target_groups
}

output "alb_target_group_default_arn" {
  description = "The ARN of the default target group"
  value       = module.alb.target_groups.default.arn
}

output "alb_zone_id" {
  description = "The zone ID of the ALB"
  value       = module.alb.zone_id
}

output "alb_listener_arns" {
  description = "Map of ALB listener ARNs"
  value       = module.alb.listeners
}

output "alb_private_dns_record" {
  description = "The Route53 record created for the ALB"
  value       = aws_route53_record.alb_private_dns.name
}

output "alb_autoscaling_attachments" {
  description = "List of autoscaling group attachments for the ALB"
  value       = {
    for k, v in aws_autoscaling_attachment.this :
    k => {
      autoscaling_group_name = v.autoscaling_group_name
      target_group_arn       = v.lb_target_group_arn
    }
  }
}
