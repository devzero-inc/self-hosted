import pathlib
import sh
from kubernetes import client, config
from kubernetes.client import V1IngressClass
from dz_installer.dz_config import DZConfig
from dz_installer.helpers import info, success, error, check_chart_is_installed
from ruamel.yaml import YAML
import click

yaml = YAML()
yaml.preserve_quotes = True

config.load_kube_config()

data_plane_deps_dir = pathlib.Path("./charts/dz-data-plane-deps")
data_plane_dir = pathlib.Path("./charts/dz-data-plane")

class DataPlane:

    @staticmethod
    def error(error_name):
        error(f"DATA_PLANE_{error_name}_ERROR")

    def check_data_plane_chart(self, force):
        info("Checking data plane...")

        try:
            if check_chart_is_installed("dz-data-plane"):
                success("Data plane is installed")
                if not force:
                    return
            else:
                info("Data plane is not installed")
        except RuntimeError as e:
            self.error(str(e))

        globals_cfg = DZConfig().data.globals
        data_plane_cfg = DZConfig().data.data_planes[DZConfig().data.data_planes.current_region]

        if not globals_cfg.domain_name or force:
            globals_cfg.domain_name = click.prompt("Please provide a domain name for the control plane.\n Examples: example.com or subdomain.example.com", prompt_suffix="\n")
            globals_cfg.save()

        if not globals_cfg.docker_hub or force:
            globals_cfg.docker_hub.access = click.confirm("Does your cluster have configured credentials for Docker Hub?", default=False)
            if not globals_cfg.docker_hub.access:
                globals_cfg.docker_hub.username = click.prompt("Please provide your Docker Hub username")
                globals_cfg.docker_hub.password = click.prompt("Please provide your Docker Hub password", hide_input=True)
                globals_cfg.docker_hub.email = click.prompt("Please provide your Docker Hub email")
            globals_cfg.save()

        data_plane_cfg.ready = True
        data_plane_cfg.save()

        success("Data plane is ready to be installed")

    def install_data_plane_chart(self):
        globals_cfg = DZConfig().data.globals
        data_plane_cfg = DZConfig().data.data_planes[DZConfig().data.data_planes.current_region]

        if not data_plane_cfg.ready:
            click.echo("Data plane is not ready to be installed. Please run checks first")
            self.error("NOT_READY")

        info("Installing data plane...")

        file = pathlib.Path(f"{data_plane_dir}/values.yaml")
        values = yaml.load(file)

        if globals_cfg.domain_name:
            values['devzero']['vault']['server'] = f"https://csi.{globals_cfg.domain_name}"

        if globals_cfg.docker_hub:
            if globals_cfg.docker_hub.access:
                values['credentials']['enable'] = False
            else:
                values['credentials']['enable'] = True
                values['credentials']['username'] = globals_cfg.docker_hub.username
                values['credentials']['password'] = globals_cfg.docker_hub.password
                values['credentials']['email'] = globals_cfg.docker_hub.email

        yaml.dump(values, file)

        try:
            sh.make("install", _cwd=data_plane_dir)
        except sh.ErrorReturnCode as err:
            click.echo(f"Error installing data plane: {err.stderr.decode('utf-8')}", err=True)
            self.error("INSTALL_FAILED")

        success("Data plane installed successfully")

    def check_data_plane_rook_ceph(self, force):
        """Check if the Rook-Ceph Helm chart is installed, check its version, and store the status in the CLI state file."""
        info("Checking Rook-Ceph...")

        chart_name = "rook-ceph"
        data_plane_cfg = DZConfig().data.data_planes[DZConfig().data.data_planes.current_region]

        if data_plane_cfg.install_rook_ceph and not force:
            click.echo("Rook-Ceph configuration already exists. Skipping...")
            return

        try:
            if check_chart_is_installed(chart_name):
                success("Rook-Ceph chart is installed.")
            else:
                click.echo("Rook-Ceph chart is not installed.")
                data_plane_cfg.install_rook_ceph = click.confirm("Do you want to install Rook-Ceph?", default=True)
                data_plane_cfg.save()
        except RuntimeError as e:
            click.echo(f"Error checking Rook-Ceph chart: {e}")
            self.error("ROOK_CEPH_CHECK_FAILED")

        success("Data Plane Rook-Ceph checks")

    def install_data_plane_rook_ceph(self):
        pass

    def check_data_plane_ingress(self, force):
        info("Checking data plane ingress...")

        data_plane_cfg = DZConfig().data.data_planes[DZConfig().data.data_planes.current_region]

        api = client.NetworkingV1Api()

        ingress_classes: list[V1IngressClass] = api.list_ingress_class().items

        for ingress_class in ingress_classes:
            if ingress_class.metadata.name == "devzero-data-ingress" and not force:
                click.echo("Data plane ingress already installed. Skipping...")
                return

        data_plane_cfg.ingress.public = click.confirm("Do you want your DevZero data plane instance to be publicly accessible?", default=False)
        data_plane_cfg.save()

        success("Data plane ingress checks done")

    def install_data_plane_ingress(self):
        info("Installing data plane ingress...")

        data_plane_cfg = DZConfig().data.data_planes[DZConfig().data.data_planes.current_region]
        globals_cfg = DZConfig().data.globals

        file = pathlib.Path(f"{data_plane_deps_dir}/values/devzero-data-ingress.yaml")
        values = yaml.load(file)

        annotations = values['controller']['service']['annotations']

        if globals_cfg.provider == "aws":
            aws_cfg = data_plane_cfg.aws.cluster
            subnets = aws_cfg.vpc.subnets.keys()

            if not data_plane_cfg.ingress.public:
                annotations['service.beta.kubernetes.io/aws-load-balancer-scheme'] = "internal"
                annotations['service.beta.kubernetes.io/aws-load-balancer-subnets'] = ",".join(subnets)
                annotations['service.beta.kubernetes.io/aws-load-balancer-backend-protocol'] = "ssl"
                annotations['service.beta.kubernetes.io/aws-load-balancer-ssl-ports'] = "https, http"
            else:
                annotations['service.beta.kubernetes.io/aws-load-balancer-scheme'] = "internet-facing"
                annotations.pop('service.beta.kubernetes.io/aws-load-balancer-subnets', None)
                annotations.pop('service.beta.kubernetes.io/aws-load-balancer-backend-protocol', None)
                annotations.pop('service.beta.kubernetes.io/aws-load-balancer-ssl-ports', None)

        yaml.dump(values, file)

        try:
            sh.make("install-devzero-data-ingress", _cwd=data_plane_deps_dir)
        except sh.ErrorReturnCode as err:
            click.echo(f"Error installing ingress controller: {err.stderr.decode('utf-8')}", err=True)
            self.error("INGRESS_INSTALL_FAILED")

        success("Control plane ingress installed successfully")

    def install_data_plane_deps(self):
        info("Installing data plane dependencies...")
        global_cfg = DZConfig().data.globals

        file = pathlib.Path(f"{data_plane_deps_dir}/values/prometheus.yaml")
        values = yaml.load(file)

        values['remoteWrite'][0]['url'] = f"https://mimir.{global_cfg.domain_name}/api/v1/push"

        try:
            sh.make("install-prometheus-operator", _cwd=data_plane_deps_dir)
            sh.make("install-prometheus", _cwd=data_plane_deps_dir)
        except sh.ErrorReturnCode as err:
            click.echo(f"Error installing dependencies: {err.stderr.decode('utf-8')}", err=True)
            self.error("DEPS_INSTALL_FAILED")

        success("Control plane dependencies installed successfully")
