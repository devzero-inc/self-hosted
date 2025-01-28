# AWS Permission Helper Module

This module helps developers understand and generate the minimum IAM permissions required to run other Devzero Terraform modules in AWS.

## Overview

When working with AWS infrastructure through Terraform, determining the exact set of IAM permissions needed can be challenging. This helper module simplifies that process by:

1. Creating an IAM user with the minimum required permissions to run a specific module
2. Generating permission files that clearly show which AWS permissions are needed
3. Helping developers understand the security requirements of the module they want to use

## Important Note

⚠️ This module is intended for **development and testing purposes only**. It should not be used in production environments.

## Use Cases

- Development and testing of new AWS infrastructure modules
- Understanding security requirements for AWS resources
- Generating baseline IAM policies for further customization
- Learning about AWS permissions required for specific infrastructure components

## How It Works

The module creates a temporary IAM user and iteratively adds required permissions until the target module can be successfully deployed. This helps identify the minimal set of permissions needed, following the principle of least privilege.

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|:--------:|
| AWS_REGION | The AWS region where resources will be created. Use "*" for all regions. | string | "" | yes |
| ACCOUNT_ID | Your AWS account ID where the permissions will be applied. | string | "" | yes |
| CLUSTER_NAME | A name prefix for the IAM resources that will be created. | string | "" | yes |
| create_local_files | Whether to generate local JSON files containing the permission sets. Set to true for local documentation. | bool | false | no |
