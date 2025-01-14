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

        if not config.globals.has_attr("control_plane"):
            setattr(config.globals, "control_plane", {})

        if not config.globals.control_plane.has_attr("domain_name") or force:
            config.globals.control_plane.domain_name = click.prompt("Please provide a domain name for the control plane.\n Examples: example.com or subdomain.example.com", prompt_suffix="\n")
            config.save()

        if not config.globals.control_plane.has_attr("docker_hub") or force:
            setattr(config.globals.control_plane, "docker_hub", {})
            config.globals.control_plane.docker_hub.access = click.confirm("Does your cluster have configured credentials for Docker Hub?", default=False)
            if not config.globals.control_plane.docker_hub.access:
                config.globals.control_plane.docker_hub.username = click.prompt("Please provide your Docker Hub username")
                config.globals.control_plane.docker_hub.password = click.prompt("Please provide your Docker Hub password", hide_input=True)
                config.globals.control_plane.docker_hub.email = click.prompt("Please provide your Docker Hub email")
            config.save()

        # ask for provisioning databases in cluster
        provision_dbs_in_cluster = click.confirm("Do you want to provision databases in cluster?", default=True)
        if not provision_dbs_in_cluster:
            # ask for connection details for mongo, redis, postgres, sqs and s3.

            if not config.globals.control_plane.has_attr("postgres_url") or force:
                config.globals.postgres_url = click.prompt(f"Please provide the database connection string for postgresql.\nExample format: postgresql://user:password@hostname:port/database", prompt_suffix="\n")
                config.save()

            if not config.globals.control_plane.has_attr("mongo_url") or force:
                config.globals.mongo_url = click.prompt(f"Please provide the database connection string for mongodb.\nExample format: mongodb://hostname:port", prompt_suffix="\n")
                config.save()

            if not config.globals.control_plane.has_attr("redis_url") or force:
                config.globals.redis_url = click.prompt(f"Please provide the redis connection string.\nExample format: redis://hostname:port", prompt_suffix="\n")
                config.save()

            if not config.globals.control_plane.has_attr("sqs_url") or force:
                config.globals.sqs_url = click.prompt(f"Please provide the sqs connection string.\nExample format: https://sqs.region.amazonaws.com/account_id/queue_name", prompt_suffix="\n")
                config.save()

            if not config.globals.control_plane.has_attr("s3_url") or force:
                config.globals.s3_url = click.prompt(f"Please provide the s3 connection string.\nExample format: s3://bucket_name", prompt_suffix="\n")
                config.save()

        # ask for arch of the data planes
        # data_plane_arch = click.prompt("Please provide the architecture of data planes (arm64/amd64)", default="amd64")
        # config.globals.data_plane_arch = data_plane_arch
        # config.save()

        click.echo("✓ Control plane is ready to be installed")
