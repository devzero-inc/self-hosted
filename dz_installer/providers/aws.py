import boto3
import click

from dz_installer.constants import AWS_CONTROL_PLANE_PERMISSIONS, AWS_DATA_PLANE_PERMISSIONS, AWS_REGIONS
from dz_installer.dz_config import DZConfig, DZDotMap
from dz_installer.helpers import error, success, info, green, red


class AWSProvider:

    def __init__(self):
        self._config = None

    @staticmethod
    def error(error_name):
        error(f"AWS_{error_name}_ERROR")

    @property
    def config(self):
        if not self._config:
            self._config = DZConfig().data
        return self._config

    def get_caller_identity(self):
        identity = {}
        try:
            sts = boto3.client("sts")
            identity = sts.get_caller_identity()
            info(
                f"Successfully authenticated with AWS. Current role: {identity['Arn']}"
            )
        except Exception as e:
            click.echo(f"Failed to authenticate with AWS: {str(e)}", err=True)
            self.error("UNABLE_TO_AUTHENTICATE")

        iam = boto3.client("iam")

        arn = identity["Arn"]
        if "assumed-role" in arn:
            role = iam.get_role(RoleName=arn.split(":assumed-role/")[1].split("/")[0])
            arn = role["Role"]["Arn"]
        return arn

    def check_permissions(self, force, perms):
        arn = self.get_caller_identity()
        iam = boto3.client("iam")
        failed_permissions = []
        permission_name = None
        try:
            # Simulate the policy to check if user has permission
            response = iam.simulate_principal_policy(
                PolicySourceArn=arn,
                ActionNames=perms,
            )

            # Check evaluation result
            for permission in response["EvaluationResults"]:
                permission_name = permission["EvalActionName"]

                if permission["EvalDecision"] != "allowed":
                    failed_permissions.append(permission_name)
                    # click.echo(f"Missing required permission: {permission_name}", err=True)
                else:
                    success(f"Has permission: {permission_name}")

        except Exception as e:
            failed_permissions.append(permission_name)
            click.echo(
                f"Error checking permission {permission_name}: {str(e)}", err=True
            )

            self.error("MISSING_AWS_SIMULATION_PERMISSION")

        if failed_permissions:
            click.echo("\nMissing required permissions:", err=True)
            for perm in failed_permissions:
                click.echo(f"  - {perm}", err=True)
            self.error("MISSING_PERMISSION_CHECK")

    def check_cluster(self, force, region, name):
        info(f"Checking EKS cluster {name} in region {region}...")
        eks = boto3.client("eks", region_name=region)
        try:
            desc_cluster = eks.describe_cluster(name=name)
        except Exception as e:
            click.echo(f"Error fetching cluster information: {str(e)}", err=True)
            self.error("CLUSTER_FAILED")
        cluster_data = desc_cluster["cluster"]

        data = DZDotMap({
            "cluster_public_access": cluster_data["resourcesVpcConfig"]["endpointPublicAccess"],
            "cluster_private_access": cluster_data["resourcesVpcConfig"]["endpointPrivateAccess"],
            "vpc": {
                "id": cluster_data["resourcesVpcConfig"]["vpcId"],
            }
        })
        click.echo(f"Cluster public access: {data.cluster_public_access}")
        click.echo(f"Cluster private access: {data.cluster_private_access}")

        for subnet in cluster_data["resourcesVpcConfig"]["subnetIds"]:
            data.vpc.subnets[subnet] = {"id": subnet}

        data.vpc.security_groups = cluster_data["resourcesVpcConfig"]["securityGroupIds"]

        subnet_ids = [*data.vpc.subnets.keys()]

        click.echo(green(f"Found VPC_ID: {data.vpc.id}"))
        click.echo(green(f"Found security groups: {data.vpc.security_groups}"))
        click.echo(green(f"Found subnets: {subnet_ids}"))

        click.echo("Checking if those subnets are public or private...")
        ec2 = boto3.client("ec2", region_name=region)

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

            k8s_cluster_tag_name = f"kubernetes.io/cluster/{name}"

            if is_public:
                click.echo(f"Subnet {subnet_id} seems to be public as it is connected to the internet gateway")
                data.vpc.subnets[subnet_id]["public"] = True

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
                            click.echo(
                                red(f"Subnet {subnet_id} has {k8s_cluster_tag_name} tag but it is not set to 'owned' or 'shared'"))

                data.vpc.subnets[subnet_id]["has_kubernetes_tags"] = has_k8s_role_tag and has_k8s_cluster_tag

                if has_k8s_role_tag and has_k8s_cluster_tag:
                    click.echo(
                        green(f"Subnet {subnet_id} has both kubernetes.io/role/elb and {k8s_cluster_tag_name} tags"))
                else:
                    click.echo(
                        red(f"Subnet {subnet_id} is missing one or both of the required tags (kubernetes.io/role/elb and {k8s_cluster_tag_name})")
                    )
            else:
                click.echo(f"Subnet {subnet_id} seems to be private as it is not connected to the internet gateway")
                data.vpc.subnets[subnet_id]["public"] = False

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
                            click.echo(
                                red(f"Subnet {subnet_id} has {k8s_cluster_tag_name} tag but it is not set to 'owned' or 'shared'"))

                data.vpc.subnets[subnet_id]["has_kubernetes_tags"] = has_k8s_role_tag and has_k8s_cluster_tag
                if has_k8s_role_tag and has_k8s_cluster_tag:
                    click.echo(green(
                        f"Subnet {subnet_id} has both kubernetes.io/role/internal-elb and {k8s_cluster_tag_name} tags"))
                else:
                    click.echo(
                        red(f"Subnet {subnet_id} is missing one or both of the required tags (kubernetes.io/role/internal-elb and {k8s_cluster_tag_name})"))

        return data

    def control_plane_permissions(self, force):
        info("Checking control plane permissions...")
        self.check_permissions(force, AWS_CONTROL_PLANE_PERMISSIONS)
        success("All required control plane permissions are granted\n")

    def control_plane_cluster(self, force):
        info("Checking control plane cluster...")

        if hasattr(self.config.control_plane.aws, "cluster_complete") and self.config.control_plane.aws.cluster_complete and not force:
            click.echo("Cluster configuration already exists, skipping...")
            return

        if click.confirm(
                "Do you already have an EKS cluster you want to use?", default=True
        ):
            info(
                "This script assumes you already changed your kubectl context to the cluster "
                "you want to use and have the appropriate credentials. If not, please do that before continuing."
            )
            self.config.control_plane.aws.region = click.prompt(
                "What is the region of the cluster", type=click.Choice(AWS_REGIONS, case_sensitive=False), default=AWS_REGIONS[0]
            )
            self.config.control_plane.aws.cluster_name = click.prompt(
                "What is the cluster name", type=str, default="devzero-cluster"
            )
            self.config.save()

            self.config.control_plane.aws.cluster = self.check_cluster(force, self.config.control_plane.aws.region, self.config.control_plane.aws.cluster_name)
            self.config.control_plane.aws.cluster_complete = True
            self.config.save()

        else:
            click.echo(
                "Sorry, the DZ CLI installer still can't handle Cluster creation for you. That should be coming soon."
            )
            click.echo("You need to create a VPC first.")
            self.error("VPC_DOES_NOT_EXIST")

    def control_plane_network(self, force):
        info("Checking control plane network...")
        pass

    def data_plane_permissions(self, force):
        info("Checking data plane permissions...")
        self.check_permissions(force, AWS_DATA_PLANE_PERMISSIONS)
        success("All required data plane permissions are granted\n")

    def data_plane_cluster(self, force):
        info("Checking data plane cluster...")
        region = click.prompt(
            "What is the region of the cluster", type=click.Choice(AWS_REGIONS, case_sensitive=False),
            default=AWS_REGIONS[0]
        )

        if not hasattr(self.config.data_planes, region):
            self.config.data_planes[region] = {}
            self.config.save()

        config = self.config.data_planes[region]

        if hasattr(config, "cluster_complete") and config.aws.cluster_complete and not force:
            click.echo("Cluster configuration already exists, skipping...")
            return

        config.aws.cluster_name = click.prompt(
            "What is the cluster name", type=str, default="devzero-cluster"
        )
        self.config.save()

        config.aws.cluster = self.check_cluster(force, region, config.aws.cluster_name)
        config.aws.cluster_complete = True
        self.config.save()

    def data_plane_network(self, force):
        info("Checking data plane network...")
        pass