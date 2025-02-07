# DevZero Self-Hosted - Terraform - AWS - Base Cluster

This directory contains the Terraform configuration files required to provision and manage the Base Cluster infrastructure. The base-cluster acts as the layer for deploying workloads, services, and applications in a cloud environment. It is designed to provision a fully functional Kubernetes cluster with the necessary networking, compute, and storage resources. It supports deployments on AWS providing a scalable and secure environment for running containerised applications.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.9 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.7.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.20.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.9 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | ../../../modules/aws/alb | n/a |
| <a name="module_derp"></a> [derp](#module\_derp) | ../../../modules/aws/derp | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 20.31.6 |
| <a name="module_kata_node_group"></a> [kata\_node\_group](#module\_kata\_node\_group) | ../../../modules/aws/kata_node_group | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.17.0 |
| <a name="module_vpn"></a> [vpn](#module\_vpn) | ../../../modules/aws/vpn | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.vault-auto-unseal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.vault-auto-unseal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.vault-auto-unseal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_route53_zone.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [null_resource.validations](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ami.devzero_amazon_eks_node_al2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster-data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster-auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |
| [aws_subnet.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.public_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_current_user_to_kms"></a> [add\_current\_user\_to\_kms](#input\_add\_current\_user\_to\_kms) | Adds the current terraform user as an admin of EKS KMS key | `bool` | `true` | no |
| <a name="input_additional_routes"></a> [additional\_routes](#input\_additional\_routes) | Additional Routes | `list(map(string))` | `[]` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Availability zones. Required if availability\_zones\_count is not set | `list(string)` | `[]` | no |
| <a name="input_availability_zones_count"></a> [availability\_zones\_count](#input\_availability\_zones\_count) | The number of availability zones available for the VPC and EKS cluster | `number` | `0` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | Cidr block | `string` | `null` | no |
| <a name="input_client_vpn_cidr_block"></a> [client\_vpn\_cidr\_block](#input\_client\_vpn\_cidr\_block) | CIDR for Client VPN IP addresses | `string` | `"10.9.0.0/22"` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Enable cluster autoscaler | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `any` | `null` | no |
| <a name="input_cluster_identity_providers"></a> [cluster\_identity\_providers](#input\_cluster\_identity\_providers) | Optional list of cluster identity providers | `map` | `{}` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name prefix to be used by resources | `string` | `"devzero"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Cluster version to use for EKS deployment | `string` | `"1.30"` | no |
| <a name="input_create_alb"></a> [create\_alb](#input\_create\_alb) | Create custom ALB pointing to the cluster node port | `bool` | `false` | no |
| <a name="input_create_derp"></a> [create\_derp](#input\_create\_derp) | Create custom DERP server | `bool` | `false` | no |
| <a name="input_create_igw"></a> [create\_igw](#input\_create\_igw) | Controls if an Internet Gateway is created for public subnets and the related routes that connect them. | `bool` | `true` | no |
| <a name="input_create_vault_auto_unseal_key"></a> [create\_vault\_auto\_unseal\_key](#input\_create\_vault\_auto\_unseal\_key) | Whether or not to create a KMS key for Vault auto unseal | `bool` | `false` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Controls if VPC should be created (it affects almost all resources) | `bool` | n/a | yes |
| <a name="input_create_vpn"></a> [create\_vpn](#input\_create\_vpn) | Controls if VPN gateway and VPN resources will be created. | `bool` | `false` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired node size | `number` | `1` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Nodes disk size in GiB | `number` | `200` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Name of the private domain | `string` | n/a | yes |
| <a name="input_eks_access_entries"></a> [eks\_access\_entries](#input\_eks\_access\_entries) | EKS Access entries | `map` | `{}` | no |
| <a name="input_enable_cluster_creator_admin_permissions"></a> [enable\_cluster\_creator\_admin\_permissions](#input\_enable\_cluster\_creator\_admin\_permissions) | Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry | `bool` | `true` | no |
| <a name="input_enable_dhcp_options"></a> [enable\_dhcp\_options](#input\_enable\_dhcp\_options) | Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type | `bool` | `true` | no |
| <a name="input_enable_kata_node_group"></a> [enable\_kata\_node\_group](#input\_enable\_kata\_node\_group) | Enable kata node groups | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `true` | no |
| <a name="input_existing_zone_id"></a> [existing\_zone\_id](#input\_existing\_zone\_id) | The existing Route53 zone ID (if use\_existing\_route53\_zone is true) | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Node instance type | `string` | `"m5.4xlarge"` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available | `list(string)` | `[]` | no |
| <a name="input_kms_key_enable_default_policy"></a> [kms\_key\_enable\_default\_policy](#input\_kms\_key\_enable\_default\_policy) | Enable default KMS key policy | `bool` | `true` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Max node size | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Min node size | `number` | `1` | no |
| <a name="input_node_role_suffix"></a> [node\_role\_suffix](#input\_node\_role\_suffix) | Suffix to use on the node group IAM role | `string` | `"-nodes-eks-node-group-"` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Should be true if you want only one NAT Gateway per availability zone. | `bool` | `true` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnets. Required if create\_vpc is false | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnets. Optionally create public subnets | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | VPC security groups to allow connection from/to cluster | `list(string)` | `[]` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_use_existing_route53_zone"></a> [use\_existing\_route53\_zone](#input\_use\_existing\_route53\_zone) | If true, skip creating a new Route53 zone and use an existing zone\_id instead | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC that the cluster will be deployed in (required if create\_vpc is false) | `string` | `null` | no |
| <a name="input_vpn_client_list"></a> [vpn\_client\_list](#input\_vpn\_client\_list) | Subnets | `set(string)` | <pre>[<br/>  "root"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The endpoint of the EKS cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the EKS cluster |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | The security group ID for the EKS cluster |
| <a name="output_eks_cluster_version"></a> [eks\_cluster\_version](#output\_eks\_cluster\_version) | The version of Kubernetes for the EKS cluster |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | The security group ID for the EKS nodes |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnet IDs |
| <a name="output_region"></a> [region](#output\_region) | The AWS region where the cluster is deployed |
| <a name="output_vault_auto_unseal_key_id"></a> [vault\_auto\_unseal\_key\_id](#output\_vault\_auto\_unseal\_key\_id) | n/a |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC where the cluster is deployed |
