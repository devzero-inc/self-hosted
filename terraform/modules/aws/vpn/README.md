# VPN

Cluster extensions are used to provision the following prerequisites:
- AWS VPN: Provisions AWS client VPN endpoint to be able to connect to an internal network through OpenVPN.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.ca](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate.client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_ec2_client_vpn_authorization_rule.vpn-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule) | resource |
| [aws_ec2_client_vpn_endpoint.vpn-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |
| [aws_ec2_client_vpn_network_association.vpn-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource |
| [aws_ec2_client_vpn_route.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_route) | resource |
| [aws_ec2_client_vpn_route.routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_route) | resource |
| [aws_s3_bucket.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_object.vpn-config-file](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.vpn_ca_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpn_ca_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpn_client_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpn_client_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpn_server_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpn_server_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [tls_cert_request.client](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_cert_request.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.client](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.client](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [aws_iam_policy_document.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_routes"></a> [additional\_routes](#input\_additional\_routes) | Additional Routes | `list(map(string))` | `[]` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | VPC security groups to allow connection from/to vpn | `list(string)` | `[]` | no |
| <a name="input_additional_server_dns_names"></a> [additional\_server\_dns\_names](#input\_additional\_server\_dns\_names) | Additional DNS names for the server certificate | `list(string)` | `[]` | no |
| <a name="input_client_vpn_cidr_block"></a> [client\_vpn\_cidr\_block](#input\_client\_vpn\_cidr\_block) | CIDR for Client VPN IP addresses | `string` | `"10.9.0.0/22"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ALB | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region name | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs to associate with the Client VPN endpoint | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_dns_resolver"></a> [vpc\_dns\_resolver](#input\_vpc\_dns\_resolver) | CIDR for VPC DNS resolver | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to associate with the Client VPN endpoint | `string` | n/a | yes |
| <a name="input_vpn_client_list"></a> [vpn\_client\_list](#input\_vpn\_client\_list) | VPN client list, we need to always keep root user to login to the VPN | `set(string)` | <pre>[<br/>  "root"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpn_ca_certificate"></a> [vpn\_ca\_certificate](#output\_vpn\_ca\_certificate) | The CA certificate for the VPN |
| <a name="output_vpn_ca_certificate_ssm"></a> [vpn\_ca\_certificate\_ssm](#output\_vpn\_ca\_certificate\_ssm) | SSM parameter name for the VPN CA certificate |
| <a name="output_vpn_ca_private_key_ssm"></a> [vpn\_ca\_private\_key\_ssm](#output\_vpn\_ca\_private\_key\_ssm) | SSM parameter name for the VPN CA private key |
| <a name="output_vpn_client_certificate_arns"></a> [vpn\_client\_certificate\_arns](#output\_vpn\_client\_certificate\_arns) | Map of client certificate ARNs for the VPN |
| <a name="output_vpn_client_certificates_ssm"></a> [vpn\_client\_certificates\_ssm](#output\_vpn\_client\_certificates\_ssm) | Map of SSM parameter names for VPN client certificates |
| <a name="output_vpn_client_config_files"></a> [vpn\_client\_config\_files](#output\_vpn\_client\_config\_files) | S3 keys for VPN client configuration files |
| <a name="output_vpn_client_private_keys_ssm"></a> [vpn\_client\_private\_keys\_ssm](#output\_vpn\_client\_private\_keys\_ssm) | Map of SSM parameter names for VPN client private keys |
| <a name="output_vpn_endpoint_id"></a> [vpn\_endpoint\_id](#output\_vpn\_endpoint\_id) | The ID of the Client VPN endpoint |
| <a name="output_vpn_network_associations"></a> [vpn\_network\_associations](#output\_vpn\_network\_associations) | List of network associations for the VPN |
| <a name="output_vpn_routes"></a> [vpn\_routes](#output\_vpn\_routes) | List of routes associated with the VPN |
| <a name="output_vpn_s3_bucket_name"></a> [vpn\_s3\_bucket\_name](#output\_vpn\_s3\_bucket\_name) | The name of the S3 bucket storing VPN configuration files |
| <a name="output_vpn_security_group_id"></a> [vpn\_security\_group\_id](#output\_vpn\_security\_group\_id) | The ID of the VPN security group |
| <a name="output_vpn_server_certificate_arn"></a> [vpn\_server\_certificate\_arn](#output\_vpn\_server\_certificate\_arn) | The ARN of the server certificate used for the VPN |
| <a name="output_vpn_server_certificate_ssm"></a> [vpn\_server\_certificate\_ssm](#output\_vpn\_server\_certificate\_ssm) | SSM parameter name for the VPN server certificate |
| <a name="output_vpn_server_private_key_ssm"></a> [vpn\_server\_private\_key\_ssm](#output\_vpn\_server\_private\_key\_ssm) | SSM parameter name for the VPN server private key |
<!-- END_TF_DOCS -->