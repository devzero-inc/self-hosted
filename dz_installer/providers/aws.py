import boto3
import click

from dz_installer.constants import AWS_CONTROL_PLANE_PERMISSIONS
from dz_installer.dz_config import DZConfig
from dz_installer.helpers import error, success, info, green, red


class AWSProvider:

    def __init__(self):
        self._config = None

    @staticmethod
    def error(error_name):
        error(f"AWS_{error_name}_ERROR")

    def control_plane_permissions(self, force):
        info("Checking control plane permissions...")
        identity = {}
        try:
            sts = boto3.client("sts")
            identity = sts.get_caller_identity()
            info(
                f"Successfully authenticated with AWS. Current role: {identity['Arn']}"
            )
        except Exception as e:
            click.echo(f"Failed to authenticate with AWS: {str(e)}", err=True)
            self.error("CP_UNABLE_TO_AUTHENTICATE")

        # Check all required control plane permissions
        iam = boto3.client("iam")

        arn = identity["Arn"]
        if "assumed-role" in arn:
            role = iam.get_role(RoleName=arn.split(":assumed-role/")[1].split("/")[0])
            arn = role["Role"]["Arn"]

        failed_permissions = []

        permission_name = None
        try:
            # Simulate the policy to check if user has permission
            response = iam.simulate_principal_policy(
                PolicySourceArn=arn,
                ActionNames=AWS_CONTROL_PLANE_PERMISSIONS,
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

            self.error("CP_MISSING_AWS_SIMULATION_PERMISSION")

        if failed_permissions:
            click.echo("\nMissing required permissions:", err=True)
            for perm in failed_permissions:
                click.echo(f"  - {perm}", err=True)
            self.error("CP_MISSING_PERMISSION_CHECK")
        else:
            success("All required control plane permissions are granted\n")

    @property
    def config(self):
        if not self._config:
            self._config = DZConfig().data
        return self._config

    def control_plane_cluster(self, force):
        info("Checking control plane cluster...")
        if hasattr(self.config.aws, "cluster_complete") and self.config.aws.cluster_complete and not force:
            click.echo("Cluster configuration already exists, skipping...")
            return

        if click.confirm(
                "Do you already have an EKS cluster you want to use?", default=True
        ):
            info(
                "This script assumes you already changed your kubectl context to the cluster "
                "you want to use and have the appropriate credentials. If not, please do that before continuing."
            )
            self.config.aws.cluster_name = click.prompt(
                "What is the cluster name", type=str, default="devzero-emoreth"
            )
            self.config.save()

            click.echo("Fetching information about the cluster...")
            eks = boto3.client("eks", region_name="us-west-1")
            try:
                desc_cluster = eks.describe_cluster(name=self.config.aws.cluster_name)
            except Exception as e:
                click.echo(f"Error fetching cluster information: {str(e)}", err=True)
                self.error("CP_CLUSTER_FAILED")
            # click.echo(desc_cluster)

            # Check if cluster has public and private endpoints enabled
            self.config.aws.cluster_public_access = desc_cluster["cluster"]["resourcesVpcConfig"]["endpointPublicAccess"]
            self.config.aws.cluster_private_access = desc_cluster["cluster"]["resourcesVpcConfig"]["endpointPrivateAccess"]
            click.echo(f"Cluster public access: {self.config.aws.cluster_public_access}")
            click.echo(f"Cluster private access: {self.config.aws.cluster_private_access}")


            cluster_data = desc_cluster["cluster"]

            self.config.aws.vpc.id = cluster_data["resourcesVpcConfig"]["vpcId"]

            for subnet in cluster_data["resourcesVpcConfig"]["subnetIds"]:
                self.config.aws.vpc.subnets[subnet] = {"id": subnet}

            self.config.aws.vpc.security_groups = cluster_data["resourcesVpcConfig"]["securityGroupIds"]
            self.config.save()

            subnet_ids = [*self.config.aws.vpc.subnets.keys()]

            click.echo(green(f"Found VPC_ID: {self.config.aws.vpc.id}"))
            click.echo(green(f"Found security groups: {self.config.aws.vpc.security_groups}"))
            click.echo(green(f"Found subnets: {subnet_ids}"))

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
                    print(rt)
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
                                click.echo(red(f"Subnet {subnet_id} has {k8s_cluster_tag_name} tag but it is not set to 'owned' or 'shared'"))

                    self.config.aws.vpc.subnets[subnet_id]["has_kubernetes_tags"] = has_k8s_role_tag and has_k8s_cluster_tag

                    if has_k8s_role_tag and has_k8s_cluster_tag:
                        click.echo(green(f"Subnet {subnet_id} has both kubernetes.io/role/elb and {k8s_cluster_tag_name} tags"))
                    else:
                        click.echo(red(f"Subnet {subnet_id} is missing one or both of the required tags (kubernetes.io/role/elb and {k8s_cluster_tag_name})"))

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
                                click.echo(red(f"Subnet {subnet_id} has {k8s_cluster_tag_name} tag but it is not set to 'owned' or 'shared'"))

                    self.config.aws.vpc.subnets[subnet_id]["has_kubernetes_tags"] = has_k8s_role_tag and has_k8s_cluster_tag
                    if has_k8s_role_tag and has_k8s_cluster_tag:
                        click.echo(green(f"Subnet {subnet_id} has both kubernetes.io/role/internal-elb and {k8s_cluster_tag_name} tags"))
                    else:
                        click.echo(red(f"Subnet {subnet_id} is missing one or both of the required tags (kubernetes.io/role/internal-elb and {k8s_cluster_tag_name})"))

            self.config.save()

            self.config.aws.cluster_complete = True
            self.config.save()

        else:
            click.echo(
                "Sorry, the DZ CLI installer still can't handle Cluster creation for you. That should be coming soon."
            )
            click.echo("You need to create a VPC first.")
            self.error("VPC_DOES_NOT_EXIST")

    def control_plane_network(self, force):
        info("Checking control plane network...")
