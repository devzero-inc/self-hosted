import pathlib
import sh
import click

from kubernetes import client, config
from kubernetes.client import V1IngressClass
from ruamel.yaml import YAML
from dz_installer.dz_config import DZConfig
from dz_installer.helpers import error, success, info, check_chart_is_installed

yaml = YAML()
yaml.preserve_quotes = True

config.load_kube_config()

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
            return

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

    def check_control_plane_ingress(self, force):
        info("Checking control plane ingress...")

        control_plane_cfg = DZConfig().data.control_plane
        api = client.NetworkingV1Api()

        ingress_classes: list[V1IngressClass] = api.list_ingress_class().items

        options = []
        for ingress_class in ingress_classes:
            options.append(ingress_class.metadata.name)

        if not control_plane_cfg.ingress or force:
            if not options:
                control_plane_cfg.ingress.install = click.confirm("No ingress classes found. Do you want to install an ingress controller?", default=True)
                control_plane_cfg.save()
            else:
                options.append("new")
                control_plane_cfg.ingress.cls = click.prompt("Please select an existing ingress class for the control plane. Use new if you want devzero to create a new one", type=click.Choice(options, case_sensitive=False), default=options[0])
                control_plane_cfg.save()

        if not control_plane_cfg.ingress.install and not control_plane_cfg.ingress.cls:
            click.echo("Cannot proceed without an ingress class")
            self.error("INGRESS_CLASS_NOT_FOUND")
        success("Control plane ingress checks passed")

    def check_control_plane_cert_manager(self, force):
        info("Checking control plane cert-manager...")

        control_plane_cfg = DZConfig().data.control_plane
        api = client.AppsV1Api()

        cluster_issuer

