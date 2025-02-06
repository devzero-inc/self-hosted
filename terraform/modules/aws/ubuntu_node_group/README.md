# Ubuntu Node Group

This node group uses `Ubuntu Jammy 22.04` as the base, with Kubernetes 1.30.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_node_cluster_role"></a> [node\_cluster\_role](#module\_node\_cluster\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | 5.51.0 |
| <a name="module_ubuntu_node_group"></a> [ubuntu\_node\_group](#module\_ubuntu\_node\_group) | terraform-aws-modules/eks/aws//modules/eks-managed-node-group | 20.31.6 |

## Resources

| Name | Type |
|------|------|
| [aws_ami.ubuntu-eks_1_30](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name | `string` | n/a | yes |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired node size | `number` | `4` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Node instance type | `string` | `"m5.4xlarge"` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Max node size | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Min node size | `number` | `4` | no |
| <a name="input_node_group_suffix"></a> [node\_group\_suffix](#input\_node\_group\_suffix) | Suffix to use on the node group name | `string` | `"-ubuntu-nodes"` | no |
| <a name="input_node_role_suffix"></a> [node\_role\_suffix](#input\_node\_role\_suffix) | Suffix to use on the node group IAM role | `string` | `"-nodes-eks-ubuntu-"` | no |
| <a name="input_nodes_key_name"></a> [nodes\_key\_name](#input\_nodes\_key\_name) | Nodes Kay Pair name | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-west-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node_group"></a> [node\_group](#output\_node\_group) | n/a |
<!-- END_TF_DOCS -->