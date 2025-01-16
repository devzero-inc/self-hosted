module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.13.0"

  name               = var.name
  load_balancer_type = var.type
  internal           = true
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  vpc_id             = var.vpc_id

  # Let the ALB module create and manage its own Security Group
  create_security_group = true

  security_groups = var.additional_security_group_ids

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "Allow HTTP traffic"
      cidr_ipv4   = var.vpc_cidr
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "Allow HTTPS traffic"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  security_group_egress_rules = {
    all_outbound = {
      ip_protocol = "-1"
      description = "Allow all outbound traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn

      forward = {
        target_group_key = "default"
      }
    }
  }

  # Define target groups as a map
  target_groups = {
    default = {
      name_prefix          = "dz"
      protocol             = "HTTP"
      port                 = 30080
      target_type          = "instance"
      create_attachment    = false
      load_balancing_cross_zone_enabled = true
      health_check = var.health_check
    }
  }

  tags = var.tags
}

resource "aws_route53_record" "alb_private_dns" {
  zone_id = var.zone_id
  name    = var.record
  type    = "CNAME"
  ttl     = 300
  records = [module.alb.dns_name]

  depends_on = [module.alb]
}

resource "aws_autoscaling_attachment" "this" {
  for_each = var.node_group_asg_names

  autoscaling_group_name = each.value
  lb_target_group_arn    = module.alb.target_groups.default.arn
}
