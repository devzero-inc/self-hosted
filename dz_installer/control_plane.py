import click


from dz_installer.dz_config import DZConfig
from dz_installer.helpers import error, check_chart_is_installed


class ControlPlane:

    @staticmethod
    def error(error_name):
        error(f"CONTROL_PLANE_{error_name}_ERROR")

    def control_plane_checks(self, force):
        click.echo("Checking control plane...")

        try:
            if check_chart_is_installed("dz-control-plane"):
                click.echo("✓ Control plane is installed")
                if not force:
                    return
        except RuntimeError as e:
            self.error(str(e))

        config = DZConfig()
        # ask for provisioning databases in cluster
        provision_dbs_in_cluster = click.confirm("Do you want to provision databases in cluster?", default=True)
        if not provision_dbs_in_cluster:
            # ask for connection details for mongo, redis, postgres, sqs and s3.

            if not config.globals.has_attr("postgres_url") or force:
                config.globals.postgres_url = click.prompt(f"Please provide the database connection string for postgresql.\nExample format: postgresql://user:password@hostname:port/database", prompt_suffix="\n")
                config.save()

            if not config.globals.has_attr("mongo_url") or force:
                config.globals.mongo_url = click.prompt(f"Please provide the database connection string for mongodb.\nExample format: mongodb://hostname:port", prompt_suffix="\n")
                config.save()

            if not config.globals.has_attr("redis_url") or force:
                config.globals.redis_url = click.prompt(f"Please provide the redis connection string.\nExample format: redis://hostname:port", prompt_suffix="\n")
                config.save()

            if not config.globals.has_attr("sqs_url") or force:
                config.globals.sqs_url = click.prompt(f"Please provide the sqs connection string.\nExample format: https://sqs.region.amazonaws.com/account_id/queue_name", prompt_suffix="\n")
                config.save()

            if not config.globals.has_attr("s3_url") or force:
                config.globals.s3_url = click.prompt(f"Please provide the s3 connection string.\nExample format: s3://bucket_name", prompt_suffix="\n")
                config.save()

        # ask for arch of the data planes
        # data_plane_arch = click.prompt("Please provide the architecture of data planes (arm64/amd64)", default="amd64")
        # config.globals.data_plane_arch = data_plane_arch
        # config.save()

        click.echo("✓ Control plane is ready to be installed")
