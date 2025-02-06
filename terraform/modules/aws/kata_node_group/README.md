# Kata Node Group

The Kata Node Group is a specialized EKS-managed node group designed to run Kata Containers within an Amazon EKS (Elastic Kubernetes Service) cluster. Kata Containers provide an extra layer of security by using lightweight virtual machines (VMs) instead of traditional container runtimes, ensuring stronger isolation between workloads.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kata_node_group"></a> [kata\_node\_group](#module\_kata\_node\_group) | terraform-aws-modules/eks/aws//modules/eks-managed-node-group | 20.31.6 |
| <a name="module_node_cluster_role"></a> [node\_cluster\_role](#module\_node\_cluster\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | 5.51.0 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | ID of the AMI used to deploy node group, default AMI is in us-west-2 for EKS 1.30 | `string` | `"ami-01e03fd5293f4b786"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name | `string` | n/a | yes |
| <a name="input_custom_ca_cert"></a> [custom\_ca\_cert](#input\_custom\_ca\_cert) | Optional custom CA certificate contents. If empty, no custom CA is injected. | `string` | `""` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired node size | `number` | `4` | no |
| <a name="input_enable_custom_ca_cert"></a> [enable\_custom\_ca\_cert](#input\_enable\_custom\_ca\_cert) | Whether to enable injection of a custom CA cert | `bool` | `false` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Node instance type | `string` | `"m5.4xlarge"` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Max node size | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Min node size | `number` | `4` | no |
| <a name="input_node_group_suffix"></a> [node\_group\_suffix](#input\_node\_group\_suffix) | Suffix to use on the node group name | `string` | `"-kata-nodes"` | no |
| <a name="input_node_role_suffix"></a> [node\_role\_suffix](#input\_node\_role\_suffix) | Suffix to use on the node group IAM role | `string` | `"-nodes-eks-kata-"` | no |
| <a name="input_nodes_key_name"></a> [nodes\_key\_name](#input\_nodes\_key\_name) | Nodes Kay Pair name | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-west-1"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME` | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node_group"></a> [node\_group](#output\_node\_group) | n/a |
