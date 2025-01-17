import pathlib
import sh
import click

from ruamel.yaml import YAML
from dz_installer.dz_config import DZConfig
from dz_installer.helpers import error, success, info, check_chart_is_installed

yaml = YAML()
yaml.preserve_quotes = True

class ControlPlane:

    @staticmethod
    def error(error_name):
        error(f"CONTROL_PLANE_{error_name}_ERROR")

    def check_control_plane_chart(self, force):
        info("Checking control plane...")

        try:
            if check_chart_is_installed("dz-control-plane"):
                success("Control plane is installed")
                if not force:
                    return False
            else:
                click.echo("Control plane is not installed")
        except RuntimeError as e:
            self.error(str(e))
            return False

        globals_cfg = DZConfig().data.globals
        control_plane_cfg = DZConfig().data.control_plane

        if force:
            del globals_cfg.control_plane
            globals_cfg.save()

        if not globals_cfg.domain_name or force:
            globals_cfg.domain_name = click.prompt("Please provide a domain name for the control plane.\n Examples: example.com or subdomain.example.com", prompt_suffix="\n")
            globals_cfg.save()

        if not control_plane_cfg.license_key or force:
            control_plane_cfg.license_key = click.prompt("Please provide your DevZero license key")
            control_plane_cfg.save()

        if not control_plane_cfg.docker_hub or force:
            control_plane_cfg.docker_hub.access = click.confirm("Does your cluster have configured credentials for Docker Hub?", default=False)
            if not control_plane_cfg.docker_hub.access:
                control_plane_cfg.docker_hub.username = click.prompt("Please provide your Docker Hub username")
                control_plane_cfg.docker_hub.password = click.prompt("Please provide your Docker Hub password", hide_input=True)
                control_plane_cfg.docker_hub.email = click.prompt("Please provide your Docker Hub email")
            control_plane_cfg.save()

        # ask for provisioning databases in cluster
        if not control_plane_cfg.provision_dbs_in_cluster or force:
            control_plane_cfg.provision_dbs_in_cluster = click.confirm("Do you want to provision databases in cluster?", default=True)
            control_plane_cfg.save()
            if not control_plane_cfg.provision_dbs_in_cluster:
                if not control_plane_cfg.postgres_url or force:
                    control_plane_cfg.postgres_url = click.prompt(f"Please provide the database connection string for postgresql.\nExample format: postgresql://user:password@hostname:port/database", prompt_suffix="\n")
                    control_plane_cfg.save()

                if not control_plane_cfg.mongo_url or force:
                    control_plane_cfg.mongo_url = click.prompt(f"Please provide the database connection string for mongodb.\nExample format: mongodb://hostname:port", prompt_suffix="\n")
                    control_plane_cfg.save()

                if not control_plane_cfg.redis_url or force:
                    control_plane_cfg.redis_url = click.prompt(f"Please provide the redis connection string.\nExample format: redis://hostname:port", prompt_suffix="\n")
                    control_plane_cfg.save()

                if not control_plane_cfg.sqs_url or force:
                    control_plane_cfg.sqs_url = click.prompt(f"Please provide the sqs connection string.\nExample format: https://sqs.region.amazonaws.com/account_id/queue_name", prompt_suffix="\n")
                    control_plane_cfg.save()

                if not control_plane_cfg.s3_url or force:
                    control_plane_cfg.s3_url = click.prompt(f"Please provide the s3 connection string.\nExample format: s3://bucket_name", prompt_suffix="\n")
                    control_plane_cfg.save()

        # ask for arch of the data planes
        # data_plane_arch = click.prompt("Please provide the architecture of data planes (arm64/amd64)", default="amd64")
        # config.data_plane_arch = data_plane_arch
        # config.save()

        success("Control plane is ready to be installed")
        return True

    def install_control_plane_chart(self, force):
        can_install = self.check_control_plane_chart(force)

        if not can_install and not force:
            # return
            pass

        info("Installing control plane...")

        globals_cfg = DZConfig().data.globals
        control_plane_cfg = DZConfig().data.control_plane

        file = pathlib.Path("./charts/dz-control-plane/values.yaml")
        values = yaml.load(file)

        click.echo()

        if globals_cfg.domain_name:
            values['domain'] = globals_cfg.domain_name

        if control_plane_cfg.license_key:
            values['backend']['licenseKey'] = control_plane_cfg.license_key

        if control_plane_cfg.docker_hub:
            if control_plane_cfg.docker_hub.access:
                values['credentials']['enable'] = False
            else:
                values['credentials']['username'] = control_plane_cfg.docker_hub.username
                values['credentials']['password'] = control_plane_cfg.docker_hub.password
                values['credentials']['email'] = control_plane_cfg.docker_hub.email

        # TODO: handle provisioning dbs in rds
        # if control_plane_cfg.has_attr("provision_dbs_in_cluster"):
        #     ...

        yaml.dump(values, file)

        try:
            sh.helm("upgrade", "--install", "devzero", "./charts/dz-control-plane", "-n", "devzero", "--create-namespace")
        except sh.ErrorReturnCode as err:
            click.echo(f"Error installing control plane: {err.stderr.decode('utf-8')}", err=True)
            self.error("INSTALL_FAILED")

        success("Control plane installed successfully")