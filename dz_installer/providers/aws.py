import datetime

import boto3
import click
from dateutil.tz import tzlocal
from rich import json

from dz_installer.constants import AWS_CONTROL_PLANE_PERMISSIONS
from dz_installer.dz_config import DZConfig
from dz_installer.helpers import error, console


class AWSProvider:

    def __init__(self):
        self._config = None

    @staticmethod
    def error(error_name):
        error(f"AWS_{error_name}_ERROR")

    def control_plane_permissions(self, force):
        click.echo("Checking control plane permissions...")
        identity = {}
        try:
            sts = boto3.client("sts")
            identity = sts.get_caller_identity()
            click.echo(
                f"Successfully authenticated with AWS. Current role: {identity['Arn']}"
            )
        except Exception as e:
            click.echo(f"Failed to authenticate with AWS: {str(e)}", err=True)
            self.error("CP_UNABLE_TO_AUTHENTICATE")

        # Check all required control plane permissions
        iam = boto3.client("iam")

        failed_permissions = []

        try:
            # Simulate the policy to check if user has permission
            response = iam.simulate_principal_policy(
                PolicySourceArn=identity["Arn"],
                ActionNames=AWS_CONTROL_PLANE_PERMISSIONS,
            )

            # Check evaluation result
            for permission in response["EvaluationResults"]:
                permission_name = permission["EvalActionName"]

                if permission["EvalDecision"] != "allowed":
                    failed_permissions.append(permission_name)
                    # click.echo(f"Missing required permission: {permission_name}", err=True)
                else:
                    click.echo(f"✓ Has permission: {permission_name}")

        except Exception as e:
            failed_permissions.append(permission_name)
            click.echo(
                f"Error checking permission {permission_name}: {str(e)}", err=True
            )

            self.error("CP_MISSING_AWS_SIMULATION_PERMISSION")

        if failed_permissions:
            click.echo("\nMissing required permissions:", err=True)
            for perm in failed_permissions:
                click.echo(f"  - {perm}", err=True)
            self.error("CP_MISSING_PERMISSION_CHECK")
        else:
            click.echo("\n✓ All required control plane permissions are granted")

    @property
    def config(self):
        if not self._config:
            self._config = DZConfig()
        return self._config

    def control_plane_cluster(self, force):
        if hasattr(self.config.aws, "cluster_complete") and self.config.aws.cluster_complete and not force:
            click.echo("Cluster configuration already exists, skipping...")
            return

        if click.confirm(
                "Do you already have an EKS cluster you want to use?", default=True
        ):
            click.echo(
                "This script assumes you already changed your kubectl context to the cluster "
                "you want to use and have the appropriate credentials. If not, please do that before continuing."
            )
            self.config.aws.cluster_name = click.prompt(
                "What is the cluster name", type=str, default="devzero-emoreth"
            )
            self.config.save()

            click.echo("Fetching information about the cluster...")
            eks = boto3.client("eks", region_name="us-west-1")
            desc_cluster = eks.describe_cluster(name=self.config.aws.cluster_name)
            # click.echo(desc_cluster)

            # Check if cluster has public and private endpoints enabled
            self.config.aws.cluster_public_access = desc_cluster["cluster"]["resourcesVpcConfig"]["endpointPublicAccess"]
            self.config.aws.cluster_private_access = desc_cluster["cluster"]["resourcesVpcConfig"]["endpointPrivateAccess"]
            click.echo(f"Cluster public access: {self.config.aws.cluster_public_access}")
            click.echo(f"Cluster private access: {self.config.aws.cluster_private_access}")


            cluster_data = desc_cluster["cluster"]
            if not self.config.aws.has_attr("vpc"):
                self.config.aws.vpc = {}

            self.config.aws.vpc.id = cluster_data["resourcesVpcConfig"]["vpcId"]
            if not hasattr(self.config.aws.vpc, "subnets"):
                self.config.aws.vpc.subnets = {}

            for subnet in cluster_data["resourcesVpcConfig"]["subnetIds"]:
                self.config.aws.vpc.subnets[subnet] = {"id": subnet}

            self.config.aws.vpc.security_groups = cluster_data["resourcesVpcConfig"]["securityGroupIds"]
            self.config.save()

            subnet_ids = [*self.config.aws.vpc.subnets.keys()]

            click.echo(console.print(f"[green] Found VPC_ID: {self.config.aws.vpc.id}"))
            click.echo(console.print(f"[green] Found security groups: {self.config.aws.vpc.security_groups}"))
            click.echo(console.print(f"[green] Found subnets: {subnet_ids}"))

            click.echo("Checking if those subnets are public or private...")
            ec2 = boto3.client("ec2", region_name="us-west-1")


            desc_subnets = ec2.describe_subnets(SubnetIds=subnet_ids)

            for subnet in desc_subnets['Subnets']:
                subnet_id = subnet['SubnetId']
                click.echo(f"Checking subnet {subnet_id}...")

                # Get route table associations for this subnet
                route_tables = ec2.describe_route_tables(
                    Filters=[{
                        'Name': 'association.subnet-id',
                        'Values': [subnet_id]
                    }]
                )['RouteTables']

                is_public = False
                # Check routes in each associated route table
                for rt in route_tables:
                    for route in rt['Routes']:
                        # Check if route goes to internet gateway
                        if route.get('GatewayId', '').startswith('igw-'):
                            is_public = True
                            break


                k8s_cluster_tag_name = f"kubernetes.io/cluster/{self.config.aws.cluster_name}"

                if is_public:
                    click.echo(f"Subnet {subnet_id} seems to be public as it is connected to the internet gateway")
                    self.config.aws.vpc.subnets[subnet_id]["public"] = True

                    subnet_tags = subnet.get('Tags', [])

                    has_k8s_role_tag = False
                    has_k8s_cluster_tag = False
                    for tag in subnet_tags:
                        if tag['Key'] == 'kubernetes.io/role/elb':
                            has_k8s_role_tag = True

                        if tag['Key'] == k8s_cluster_tag_name:
                            if tag['Value'] in ["owned", "shared"]:
                                has_k8s_cluster_tag = True
                            else:
                                click.echo(console.print(f"[red]Subnet {subnet_id} has {k8s_cluster_tag_name} tag but it is not set to 'owned' or 'shared'"))

                    self.config.aws.vpc.subnets[subnet_id]["has_kubernetes_tags"] = has_k8s_role_tag and has_k8s_cluster_tag

                    if has_k8s_role_tag and has_k8s_cluster_tag:
                        click.echo(console.print(f"[green]Subnet {subnet_id} has both kubernetes.io/role/elb and {k8s_cluster_tag_name} tags"))
                    else:
                        click.echo(console.print(f"[red]Subnet {subnet_id} is missing one or both of the required tags (kubernetes.io/role/elb and {k8s_cluster_tag_name})"))

                else:
                    click.echo(f"Subnet {subnet_id} seems to be private as it is not connected to the internet gateway")
                    self.config.aws.vpc.subnets[subnet_id]["public"] = False

                    subnet_tags = subnet.get('Tags', [])

                    has_k8s_role_tag = False
                    has_k8s_cluster_tag = False
                    for tag in subnet_tags:
                        if tag['Key'] == 'kubernetes.io/role/internal-elb':
                            has_k8s_role_tag = True
                        if tag['Key'] == k8s_cluster_tag_name:
                            if tag['Value'] in ["owned", "shared"]:
                                has_k8s_cluster_tag = True
                            else:
                                click.echo(f"[red]Subnet {subnet_id} has {k8s_cluster_tag_name} tag but it is not set to 'owned' or 'shared'")

                    self.config.aws.vpc.subnets[subnet_id]["has_kubernetes_tags"] = has_k8s_role_tag and has_k8s_cluster_tag
                    if has_k8s_role_tag and has_k8s_cluster_tag:
                        click.echo(console.print(f"[green]Subnet {subnet_id} has both kubernetes.io/role/internal-elb and {k8s_cluster_tag_name} tags"))
                    else:
                        click.echo(console.print(f"[red]Subnet {subnet_id} is missing one or both of the required tags (kubernetes.io/role/internal-elb and {k8s_cluster_tag_name})"))

            self.config.save()

            self.config.aws.cluster_complete = True
            self.config.save()

            # subnets = {
            #     "Subnets": [
            #         {
            #             "AvailabilityZoneId": "usw1-az1",
            #             "MapCustomerOwnedIpOnLaunch": False,
            #             "OwnerId": "484907513542",
            #             "AssignIpv6AddressOnCreation": False,
            #             "Ipv6CidrBlockAssociationSet": [],
            #             "Tags": [
            #                 {
            #                     "Key": "Name",
            #                     "Value": "devzero-emoreth-vpc-private-us-west-1b",
            #                 }
            #             ],
            #             "SubnetArn": "arn:aws:ec2:us-west-1:484907513542:subnet/subnet-013c95d7871248df9",
            #             "EnableDns64": False,
            #             "Ipv6Native": False,
            #             "PrivateDnsNameOptionsOnLaunch": {
            #                 "HostnameType": "ip-name",
            #                 "EnableResourceNameDnsARecord": False,
            #                 "EnableResourceNameDnsAAAARecord": False,
            #             },
            #             "BlockPublicAccessStates": {"InternetGatewayBlockMode": "off"},
            #             "SubnetId": "subnet-013c95d7871248df9",
            #             "State": "available",
            #             "VpcId": "vpc-0ec9e7945245317ca",
            #             "CidrBlock": "10.0.112.0/20",
            #             "AvailableIpAddressCount": 3969,
            #             "AvailabilityZone": "us-west-1b",
            #             "DefaultForAz": False,
            #             "MapPublicIpOnLaunch": False,
            #         },
            #         {
            #             "AvailabilityZoneId": "usw1-az3",
            #             "MapCustomerOwnedIpOnLaunch": False,
            #             "OwnerId": "484907513542",
            #             "AssignIpv6AddressOnCreation": False,
            #             "Ipv6CidrBlockAssociationSet": [],
            #             "Tags": [
            #                 {
            #                     "Key": "Name",
            #                     "Value": "devzero-emoreth-vpc-private-us-west-1a",
            #                 }
            #             ],
            #             "SubnetArn": "arn:aws:ec2:us-west-1:484907513542:subnet/subnet-0402d93b309ac1268",
            #             "EnableDns64": False,
            #             "Ipv6Native": False,
            #             "PrivateDnsNameOptionsOnLaunch": {
            #                 "HostnameType": "ip-name",
            #                 "EnableResourceNameDnsARecord": False,
            #                 "EnableResourceNameDnsAAAARecord": False,
            #             },
            #             "BlockPublicAccessStates": {"InternetGatewayBlockMode": "off"},
            #             "SubnetId": "subnet-0402d93b309ac1268",
            #             "State": "available",
            #             "VpcId": "vpc-0ec9e7945245317ca",
            #             "CidrBlock": "10.0.96.0/20",
            #             "AvailableIpAddressCount": 3969,
            #             "AvailabilityZone": "us-west-1a",
            #             "DefaultForAz": False,
            #             "MapPublicIpOnLaunch": False,
            #         },
            #     ],
            #     "ResponseMetadata": {
            #         "RequestId": "46fe3c1f-0438-4a9b-9564-4058216b5b05",
            #         "HTTPStatusCode": 200,
            #         "HTTPHeaders": {
            #             "x-amzn-requestid": "46fe3c1f-0438-4a9b-9564-4058216b5b05",
            #             "cache-control": "no-cache, no-store",
            #             "strict-transport-security": "max-age=31536000; includeSubDomains",
            #             "vary": "accept-encoding",
            #             "content-type": "text/xml;charset=UTF-8",
            #             "content-length": "2554",
            #             "date": "Fri, 17 Jan 2025 15:09:19 GMT",
            #             "server": "AmazonEC2",
            #         },
            #         "RetryAttempts": 0,
            #     },
            # }
            # # self.config.aws.cluster_arn = cluster_data["arn"]
            # # self.config.aws.cluster_endpoint = cluster_data["endpoint"]
            # # self.config.aws.cluster_role_arn = cluster_data["roleArn"]
            # # self.config.aws.cluster_certificate_authority = cluster_data["certificateAuthority"]["data"]
            # # self.config.aws.cluster_version = cluster_data["version"]
            # # self.config.aws.cluster_oidc_issuer = cluster_data["identity"]["oidc"]["issuer"]
            # # self.config.aws.cluster_platform_version = cluster_data["platformVersion"]
            # # self.config.aws.cluster_tags = cluster_data["tags"]
            # # self.config.aws.cluster_encryption_config = cluster_data["encryptionConfig"]
            # # self.config.aws.cluster_health = cluster_data["health"]
            # # self.config.aws.cluster_access_config = cluster_data["accessConfig"]
            # # self.config.aws.cluster_upgrade_policy = cluster_data["upgradePolicy"]
            #
            # cluster = {
            #     "ResponseMetadata": {
            #         "RequestId": "f0d094e8-d0e9-404a-91a1-92c26c614ded",
            #         "HTTPStatusCode": 200,
            #         "HTTPHeaders": {
            #             "date": "Fri, 17 Jan 2025 14:54:19 GMT",
            #             "content-type": "application/json",
            #             "content-length": "3631",
            #             "connection": "keep-alive",
            #             "x-amzn-requestid": "f0d094e8-d0e9-404a-91a1-92c26c614ded",
            #             "access-control-allow-origin": "*",
            #             "access-control-allow-headers": "*,Authorization,Date,X-Amz-Date,X-Amz-Security-Token,X-Amz-Target,content-type,x-amz-content-sha256,x-amz-user-agent,x-amzn-platform-id,x-amzn-trace-id",
            #             "x-amz-apigw-id": "EiZMZHhayK4EV6Q=",
            #             "access-control-allow-methods": "GET,HEAD,PUT,POST,DELETE,OPTIONS",
            #             "access-control-expose-headers": "x-amzn-errortype,x-amzn-errormessage,x-amzn-trace-id,x-amzn-requestid,x-amz-apigw-id,date",
            #             "x-amzn-trace-id": "Root=1-678a6f1b-349887ac7f177945374876ad",
            #         },
            #         "RetryAttempts": 0,
            #     },
            #     "cluster": {
            #         "name": "devzero-emoreth",
            #         "arn": "arn:aws:eks:us-west-1:484907513542:cluster/devzero-emoreth",
            #         "createdAt": datetime.datetime(
            #             2025, 1, 13, 19, 13, 1, 78000, tzinfo=tzlocal()
            #         ),
            #         "version": "1.30",
            #         "endpoint": "https://BD6430977001D7722F60C8FF2019109C.yl4.us-west-1.eks.amazonaws.com",
            #         "roleArn": "arn:aws:iam::484907513542:role/devzero-emoreth-cluster-20250113221231470600000001",
            #         "resourcesVpcConfig": {
            #             "subnetIds": [
            #                 "subnet-013c95d7871248df9",
            #                 "subnet-0402d93b309ac1268",
            #             ],
            #             "securityGroupIds": ["sg-081775e601fe3e3ed"],
            #             "clusterSecurityGroupId": "sg-0ad2e698df8daa51d",
            #             "vpcId": "vpc-0ec9e7945245317ca",
            #             "endpointPublicAccess": True,
            #             "endpointPrivateAccess": True,
            #             "publicAccessCidrs": ["0.0.0.0/0"],
            #         },
            #         "kubernetesNetworkConfig": {
            #             "serviceIpv4Cidr": "172.20.0.0/16",
            #             "ipFamily": "ipv4",
            #             "elasticLoadBalancing": {"enabled": False},
            #         },
            #         "logging": {
            #             "clusterLogging": [
            #                 {
            #                     "types": [
            #                         "api",
            #                         "audit",
            #                         "authenticator",
            #                         "controllerManager",
            #                         "scheduler",
            #                     ],
            #                     "enabled": True,
            #                 }
            #             ]
            #         },
            #         "identity": {
            #             "oidc": {
            #                 "issuer": "https://oidc.eks.us-west-1.amazonaws.com/id/BD6430977001D7722F60C8FF2019109C"
            #             }
            #         },
            #         "status": "ACTIVE",
            #         "certificateAuthority": {
            #             "data": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJUVRGT0RRK2IyZ293RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeE1UTXlNakV4TXpCYUZ3MHpOVEF4TVRFeU1qRTJNekJhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUMvSTJEZmtZTFdOSVc2aW9PelMwN2RFeWY3eDdUTnJ4ckRiTzEySytpUU92cEhvYlk2VFJBczVBUFAKby9UZUpZT2ZWYmZRLzk2ejJoYURXNUtUZWNMdzlzaG1xZU04WDVQQ2VrcWJLVDVzS0Yza1YvSW1iUGUrYnQ1Rwo3ZFJoZVlPTzFVWnZFb1BYS3UvMktwV3lLQ0ttRm1XeFJBT2JXSE5JZ1pRTXFlYWl6bDhuQlI5K0VxNjFYUmNSCkpPU1hoLzFBcG1zZTZ6QlI2dCtWd1JXc2RaZnJBYkF5dUlMOTBZMU1WeGoxamxwNVlKZWJRVzluYks5dUJMUTUKZnlJbW05c2V3RElTampkR3ZKQ28ydjlUNjhmZkNEWUgvU01oVm9WWlB0QWJTUzhiSEl1aWhsSm5XVmpMS0xFVApIYU1nQWtJSXNraksvajl6K3laODkza09pMzB0QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTT0paWUk2aG91ODN0RFRSMzB4Q3F4WFBFNnZEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ0lRQW1Lb3FLcAo3R0J4c1RKN1U4VEVERm5GUlBkR1BZNDV6ZS9sa1ZQUVkzYitjOTlxaWJhMU5TNDg5RmlQejQzSWdaaFNyQVRYClV6Mm9PWkVTSzdCR1dhUkJEQndIV08zUkdhQUZSYVcvbjZLRVBjOEFHaHB4bFAxNHlEVWIwMEZXVTFsb0NXd3gKNXd2Vmdldk9CVDFPdWMrREdvNUM0SnhCWW1ONUNzMHZWeHFTR2FpVUdaUEZ3N0NINHEva3RYMENzZmNVemJSVwo2a0pkd3FmbXRYL1o1bzZHTFlzR2oxNFM1NFExVVVyclZrZWszT2NDL1lJR014ZUhwQjhqdmFEZjEwODVKRlpkCjVXYWtPQ25iSllIUEExRHdBRlJhWkp3aStPd25saXJSbGhRY084MC9KVHBnZkNFTnpLU2FwWUxnMklLMnVWNS8KNFhWSWJ6dytuZzd1Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
            #         },
            #         "platformVersion": "eks.24",
            #         "tags": {"terraform-aws-modules": "eks"},
            #         "encryptionConfig": [
            #             {
            #                 "resources": ["secrets"],
            #                 "provider": {
            #                     "keyArn": "arn:aws:kms:us-west-1:484907513542:key/3745dfc6-a4c9-49f5-a9f9-936c4f76a06f"
            #                 },
            #             }
            #         ],
            #         "health": {"issues": []},
            #         "accessConfig": {"authenticationMode": "API_AND_CONFIG_MAP"},
            #         "upgradePolicy": {"supportType": "EXTENDED"},
            #     },
            # }

        else:
            click.echo(
                "Sorry, the DZ CLI installer still can't handle Cluster creation for you. That should be coming soon."
            )
            click.echo("You need to create a VPC first.")
            self.error("VPC_DOES_NOT_EXIST")
