# AWS Permission Helper Module

This module helps developers understand and generate the minimum IAM permissions required to run other Devzero Terraform
modules in AWS.

## Overview

When working with AWS infrastructure through Terraform, determining the exact set of IAM permissions needed can be
challenging. This helper module simplifies that process by:

1. Creating an IAM user with the minimum required permissions to run a specific module
2. Generating permission files that clearly show which AWS permissions are needed
3. Helping developers understand the security requirements of the module they want to use

## Important Note

⚠️ This module is intended for **development and testing purposes only**. It should not be used in production
environments.

## Use Cases

- Development and testing of new AWS infrastructure modules
- Understanding security requirements for AWS resources
- Generating baseline IAM policies for further customization
- Learning about AWS permissions required for specific infrastructure components

## How It Works

### Before you start

Replace the aws provider region on main.tf with the region you want to test.

Check the variables on terraform.tfvars and adjust them to your needs.

### Creating resources
The module creates(optionally) a temporary IAM user and iteratively adds required permissions until the target module
can be successfully deployed. This helps identify the minimal set of permissions needed, following the principle of
least privilege.

This user can be used to deploy devzero example clusters. You can create AWS credentials for this user and use them to
deploy the cluster, adjusting the terraform provider configurations as needed.

### Running the module

After setting the variables, run the following commands:

```shell
terraform init
```
and then:
```shell
terraform apply
```

Use the generated resources as you wish, an then you can delete those resources with:
```shell
terraform destroy
```

## Generating policies only

If you don't need to create the IAM user, you can set the `create_local_files` variable to `true`. This will generate
the permission sets only and not create the IAM user. Note that this will still create the IAM policies, which then, can
be deleted using `terraform destroy`.

## Adding policy restrictions

You can use the variables `condition_resources` and `condition_requests` to add more fine grained restrictions to the
policies (Some examples on `terraform.tfvars` file). 

## Variables

| Variable            | Description                                                                                               | Type        | Default | Required |
|---------------------|-----------------------------------------------------------------------------------------------------------|-------------|---------|:--------:|
| AWS_REGION          | The AWS region where resources will be created. Use "*" for all regions.                                  | string      | ""      |   yes    |
| ACCOUNT_ID          | Your AWS account ID where the permissions will be applied.                                                | string      | ""      |   yes    |
| CLUSTER_NAME        | The cluster name that will be created. Some permissions are scoped to the cluster name.                   | string      | ""      |   yes    |
| create_local_files  | Whether to generate local JSON files containing the permission sets. Set to true for local documentation. | bool        | false   |    no    |
| create_iam_user     | Whether to create an IAM user with the generated permissions.                                             | bool        | false   |    no    |
| condition_resources | List of resource conditions to restrict API calls.                                                        | map(string) | {}      |    no    |
| condition_requests  | List of request conditions to restrict API calls.                                                         | map(string) | {}      |    no    |
| tags                | A map of tags to add to all resources.                                                                    | map(string) | {}      |    no    |


## TODO: 
- Allow creation of local files without creating the IAM policies.