import pathlib
import sh
import click

from ruamel.yaml import YAML
from dz_installer.dz_config import DZConfig
from dz_installer.helpers import error, check_chart_is_installed

yaml = YAML()
yaml.preserve_quotes = True

class ControlPlane:

    @staticmethod
    def error(error_name):
        error(f"CONTROL_PLANE_{error_name}_ERROR")

    def checks(self, force):
        click.echo("Checking control plane...")

        try:
            if check_chart_is_installed("dz-control-plane"):
                click.echo("✓ Control plane is installed")
                if not force:
                    return False
        except RuntimeError as e:
            self.error(str(e))
            return False

        config = DZConfig()

        if force:
            setattr(config, "control_plane", {})

        if not config.globals.has_attr("domain_name") or force:
            config.globals.domain_name = click.prompt("Please provide a domain name for the control plane.\n Examples: example.com or subdomain.example.com", prompt_suffix="\n")
            config.save()

        if not config.control_plane.has_attr("license_key") or force:
            config.control_plane.license_key = click.prompt("Please provide your DevZero license key")
            config.save()

        if not config.control_plane.has_attr("docker_hub") or force:
            setattr(config.control_plane, "docker_hub", {})
            config.control_plane.docker_hub.access = click.confirm("Does your cluster have configured credentials for Docker Hub?", default=False)
            if not config.control_plane.docker_hub.access:
                config.control_plane.docker_hub.username = click.prompt("Please provide your Docker Hub username")
                config.control_plane.docker_hub.password = click.prompt("Please provide your Docker Hub password", hide_input=True)
                config.control_plane.docker_hub.email = click.prompt("Please provide your Docker Hub email")
            config.save()

        # ask for provisioning databases in cluster
        if not config.control_plane.has_attr("provision_dbs_in_cluster") or force:
            config.control_plane.provision_dbs_in_cluster = click.confirm("Do you want to provision databases in cluster?", default=True)
            if not config.control_plane.provision_dbs_in_cluster:
                if not config.control_plane.has_attr("postgres_url") or force:
                    config.postgres_url = click.prompt(f"Please provide the database connection string for postgresql.\nExample format: postgresql://user:password@hostname:port/database", prompt_suffix="\n")
                    config.save()

                if not config.control_plane.has_attr("mongo_url") or force:
                    config.mongo_url = click.prompt(f"Please provide the database connection string for mongodb.\nExample format: mongodb://hostname:port", prompt_suffix="\n")
                    config.save()

                if not config.control_plane.has_attr("redis_url") or force:
                    config.redis_url = click.prompt(f"Please provide the redis connection string.\nExample format: redis://hostname:port", prompt_suffix="\n")
                    config.save()

                if not config.control_plane.has_attr("sqs_url") or force:
                    config.sqs_url = click.prompt(f"Please provide the sqs connection string.\nExample format: https://sqs.region.amazonaws.com/account_id/queue_name", prompt_suffix="\n")
                    config.save()

                if not config.control_plane.has_attr("s3_url") or force:
                    config.s3_url = click.prompt(f"Please provide the s3 connection string.\nExample format: s3://bucket_name", prompt_suffix="\n")
                    config.save()

        # ask for arch of the data planes
        # data_plane_arch = click.prompt("Please provide the architecture of data planes (arm64/amd64)", default="amd64")
        # config.data_plane_arch = data_plane_arch
        # config.save()

        click.echo("✓ Control plane is ready to be installed")
        return True

    def install(self, force):
        can_install = self.checks(force)

        if not can_install and not force:
            # return
            pass

        click.echo("Installing control plane...")

        config = DZConfig()
        file = pathlib.Path("./charts/dz-control-plane/values.yaml")
        values = yaml.load(file)

        click.echo()

        if config.globals.domain_name:
            values['domain'] = config.globals.domain_name

        if config.control_plane.license_key:
            values['backend']['licenseKey'] = config.control_plane.license_key

        if config.control_plane.docker_hub:
            if config.control_plane.docker_hub.access:
                values['credentials']['enable'] = False
            else:
                values['credentials']['username'] = config.control_plane.docker_hub.username
                values['credentials']['password'] = config.control_plane.docker_hub.password
                values['credentials']['email'] = config.control_plane.docker_hub.email

        # TODO: handle provisioning dbs in rds
        # if config.control_plane.has_attr("provision_dbs_in_cluster"):
        #     ...

        yaml.dump(values, file)

        try:
            sh.helm("upgrade", "--install", "devzero", "./charts/dz-control-plane", "-n", "devzero", "--create-namespace")
        except sh.ErrorReturnCode as err:
            click.echo(f"Error installing control plane: {err.stderr.decode('utf-8')}", err=True)
            self.error("INSTALL_FAILED")
