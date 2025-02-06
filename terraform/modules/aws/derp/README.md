# DERP (Designated Encrypted Relay for Packets)

DERP (Designated Encrypted Relay for Packets) is a relay server designed to help devices securely communicate with each other, even when they are behind NAT (Network Address Translation) or firewalls that block direct peer-to-peer connections. DERP servers are primarily used to support connectivity in systems where peer-to-peer connections may fail due to network constraints.

In the context of cloud infrastructure, DERP servers ensure reliable, encrypted communication between distributed nodes, especially in Kubernetes clusters, remote development environments, and private networks.

For more information, check out Taiscale's documentation [here](https://tailscale.com/kb/1232/derp-servers).

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.derp_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.derp_eip_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_instance.derp_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.derp_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_eip.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eip) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_egress_cidr_blocks"></a> [egress\_cidr\_blocks](#input\_egress\_cidr\_blocks) | CIDR blocks for egress access | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_existing_eip_id"></a> [existing\_eip\_id](#input\_existing\_eip\_id) | Existing Elastic IP allocation ID to use (optional) | `string` | `""` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Server hostname, required for public derps | `string` | `""` | no |
| <a name="input_ingress_cidr_blocks"></a> [ingress\_cidr\_blocks](#input\_ingress\_cidr\_blocks) | CIDR blocks for ingress access | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type 'm6in.2xlarge' recommended for bandwidth intensive deployments | `string` | `"t2.medium"` | no |
| <a name="input_public_derp"></a> [public\_derp](#input\_public\_derp) | Associates EIP with server instance | `bool` | `false` | no |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Existing security group ID to use (optional) | `string` | `""` | no |
| <a name="input_security_group_prefix"></a> [security\_group\_prefix](#input\_security\_group\_prefix) | Security group prefix | `string` | `"devzero"` | no |
| <a name="input_ssh_cidr_blocks"></a> [ssh\_cidr\_blocks](#input\_ssh\_cidr\_blocks) | CIDR blocks for SSH access | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | SSH keypair name | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Existing subnet ID to deploy EC2 in | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | Root volume size in GB | `number` | `20` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Existing VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_derp_server_elastic_ip"></a> [derp\_server\_elastic\_ip](#output\_derp\_server\_elastic\_ip) | n/a |
| <a name="output_derp_server_private_ip"></a> [derp\_server\_private\_ip](#output\_derp\_server\_private\_ip) | n/a |
| <a name="output_derp_server_public_ip"></a> [derp\_server\_public\_ip](#output\_derp\_server\_public\_ip) | n/a |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | n/a |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | n/a |
