# Application Load Balancer (ALB)

An Application Load Balancer (ALB) is a highly available, scalable service offered by AWS that automatically distributes incoming application traffic across multiple targets, such as EC2 instances, containers, IP addresses, and Lambda functions. It operates at the application layer (Layer 7) of the OSI model, making it ideal for HTTP and HTTPS traffic routing.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | 9.13.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_route53_record.alb_private_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | VPC security groups to allow connection from/to vpn | `list(string)` | `[]` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | Certificate ARN to be used with load balancer | `string` | n/a | yes |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | Configuration for the health check | <pre>object({<br/>    enabled             = bool<br/>    path                = string<br/>    interval            = number<br/>    timeout             = number<br/>    healthy_threshold   = number<br/>    unhealthy_threshold = number<br/>    matcher             = string<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "healthy_threshold": 2,<br/>  "interval": 30,<br/>  "matcher": "200",<br/>  "path": "/",<br/>  "timeout": 5,<br/>  "unhealthy_threshold": 2<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix to be used by resources | `string` | `"devzero"` | no |
| <a name="input_node_group_asg_names"></a> [node\_group\_asg\_names](#input\_node\_group\_asg\_names) | Map of Auto Scaling Group names for the ALB | `map(string)` | n/a | yes |
| <a name="input_record"></a> [record](#input\_record) | Record to be added for the ALB | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs to associate with the Client VPN endpoint | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Target port for the service | `number` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | Type of the load balancer | `string` | `"application"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR block | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to associate with the Client VPN endpoint | `string` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Zone id to attach domain to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | The ARN of the ALB |
| <a name="output_alb_autoscaling_attachments"></a> [alb\_autoscaling\_attachments](#output\_alb\_autoscaling\_attachments) | List of autoscaling group attachments for the ALB |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | The DNS name of the ALB |
| <a name="output_alb_listener_arns"></a> [alb\_listener\_arns](#output\_alb\_listener\_arns) | Map of ALB listener ARNs |
| <a name="output_alb_private_dns_record"></a> [alb\_private\_dns\_record](#output\_alb\_private\_dns\_record) | The Route53 record created for the ALB |
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | The security group ID associated with the ALB |
| <a name="output_alb_target_group_arns"></a> [alb\_target\_group\_arns](#output\_alb\_target\_group\_arns) | Map of ALB target group ARNs |
| <a name="output_alb_target_group_default_arn"></a> [alb\_target\_group\_default\_arn](#output\_alb\_target\_group\_default\_arn) | The ARN of the default target group |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | The zone ID of the ALB |
