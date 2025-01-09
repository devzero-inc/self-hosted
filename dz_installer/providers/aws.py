import boto3
import click

from dz_installer.constants import AWS_CONTROL_PLANE_PERMISSIONS
from dz_installer.helpers import error


class AWSProvider:

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
        iam = boto3.client('iam')

        failed_permissions = []

        try:
            # Simulate the policy to check if user has permission
            response = iam.simulate_principal_policy(
                PolicySourceArn=identity['Arn'],
                ActionNames=AWS_CONTROL_PLANE_PERMISSIONS
            )

            # Check evaluation result
            for permission in response['EvaluationResults']:
                permission_name = permission["EvalActionName"]

                if permission['EvalDecision'] != 'allowed':
                    failed_permissions.append(permission_name)
                    # click.echo(f"Missing required permission: {permission_name}", err=True)
                else:
                    click.echo(f"✓ Has permission: {permission_name}")

        except Exception as e:
            failed_permissions.append(permission_name)
            click.echo(f"Error checking permission {permission_name}: {str(e)}", err=True)

            self.error("CP_MISSING_AWS_SIMULATION_PERMISSION")

        if failed_permissions:
            click.echo("\nMissing required permissions:", err=True)
            for perm in failed_permissions:
                click.echo(f"  - {perm}", err=True)
            self.error("CP_MISSING_PERMISSION_CHECK")
        else:
            click.echo("\n✓ All required control plane permissions are granted")
