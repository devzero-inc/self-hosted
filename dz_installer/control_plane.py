import pathlib
import sh
import click

from kubernetes import client, config
from kubernetes.client import V1IngressClass
from ruamel.yaml import YAML
from dz_installer.dz_config import DZConfig, DZDotMap
from dz_installer.helpers import error, success, info, check_chart_is_installed

yaml = YAML()
yaml.preserve_quotes = True

config.load_kube_config()

control_plane_deps_dir = pathlib.Path("./charts/dz-control-plane-deps")
control_plane_dir = pathlib.Path("./charts/dz-control-plane")

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
                    return
            else:
                click.echo("Control plane is not installed")
        except RuntimeError as e:
            self.error(str(e))

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

        control_plane_cfg.ready = True
        control_plane_cfg.save()

        success("Control plane is ready to be installed")

    def install_control_plane_chart(self):
        globals_cfg = DZConfig().data.globals
        control_plane_cfg = DZConfig().data.control_plane

        if not control_plane_cfg.ready:
            click.echo("Control plane is not ready to be installed. Please run checks first")
            self.error("NOT_READY")

        info("Installing control plane...")

        file = pathlib.Path(f"{control_plane_dir}/values.yaml")
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

        yaml.dump(values, file)

        try:
            sh.make("install", _cwd=control_plane_dir)
        except sh.ErrorReturnCode as err:
            click.echo(f"Error installing control plane: {err.stderr.decode('utf-8')}", err=True)
            self.error("INSTALL_FAILED")

        success("Control plane installed successfully")

    def check_control_plane_ingress(self, force):
        info("Checking control plane ingress...")

        control_plane_cfg = DZConfig().data.control_plane

        if control_plane_cfg.ingress.cls and not force:
            click.echo("Ingress configuration already exists, skipping...")
            return

        api = client.NetworkingV1Api()

        ingress_classes: list[V1IngressClass] = api.list_ingress_class().items

        options = []
        for ingress_class in ingress_classes:
            options.append(ingress_class.metadata.name)

        if not options:
            control_plane_cfg.ingress.install = click.confirm("No ingress classes found. Do you want to install an ingress controller?", default=True)
        else:
            options.append("new")
            control_plane_cfg.ingress.cls = click.prompt("Please select an existing ingress class for the control plane. Use new if you want devzero to install nginx ingress controller", type=click.Choice(options, case_sensitive=False), default=options[0])

        control_plane_cfg.save()

        if not control_plane_cfg.ingress.install and not control_plane_cfg.ingress.cls:
            click.echo("Cannot proceed without an ingress class")
            self.error("INGRESS_CLASS_NOT_FOUND")
        success("Control plane ingress checks done")

    def install_control_plane_ingress(self):
        info("Installing control plane ingress...")
        control_plane_cfg = DZConfig().data.control_plane

        globals_cfg = DZConfig().data.globals

        if not control_plane_cfg.ingress.cls and not control_plane_cfg.ingress.install:
            click.echo("Ingress checks missing. Please run checks first")
            return

        if control_plane_cfg.ingress.install or control_plane_cfg.ingress.cls == "new":
            file = pathlib.Path(f"{control_plane_deps_dir}/values/ingress-nginx.yaml")
            values = yaml.load(file)

            annotations = values['controller']['service']['annotations']

            if globals_cfg.provider == "aws":
                aws_cfg = DZConfig().data.aws
                subnets = aws_cfg.vpc.subnets.keys()

                public = False
                for subnet in subnets:
                    if aws_cfg.vpc.subnets[subnet].public:
                        public = True
                        break

                if not public:
                    annotations['service.beta.kubernetes.io/aws-load-balancer-scheme'] = "internal"
                    annotations['service.beta.kubernetes.io/aws-load-balancer-subnets'] = ",".join(subnets)
                    annotations['service.beta.kubernetes.io/aws-load-balancer-backend-protocol'] = "ssl"
                    annotations['service.beta.kubernetes.io/aws-load-balancer-ssl-ports'] = "https, http"

                if control_plane_cfg.cert_manager.external:
                    annotations['service.beta.kubernetes.io/aws-load-balancer-ssl-cert'] = control_plane_cfg.cert_manager.cert_arn

            yaml.dump(values, file)

            try:
                sh.make("install-ingress-nginx", _cwd=control_plane_deps_dir)
            except sh.ErrorReturnCode as err:
                click.echo(f"Error installing ingress controller: {err.stderr.decode('utf-8')}", err=True)
                self.error("INGRESS_INSTALL_FAILED")

        success("Control plane ingress installed successfully")

    def check_control_plane_cert_manager(self, force):
        info("Checking control plane certificates...")

        control_plane_cfg = DZConfig().data.control_plane
        global_cfg = DZConfig().data.globals

        if (control_plane_cfg.cert_manager.install or control_plane_cfg.cert_manager.external) and not force:
            click.echo("Certificate configuration already exists, skipping...")
            return

        api = client.CustomObjectsApi()

        group = "cert-manager.io"
        version = "v1"
        plural = "clusterissuers"

        issuers = []
        try:
            # Fetch all ClusterIssuer objects
            cluster_issuers = api.list_cluster_custom_object(group, version, plural)
            for ci in cluster_issuers.get("items", []):
                issuers.append(ci["metadata"]["name"])
        except client.ApiException:
            pass

        if not issuers:
            click.echo("No cluster issuers found")
            control_plane_cfg.cert_manager.install = click.confirm("Do you want to install cert-manager to provision certificates in-cluster?", default=True)

            if not control_plane_cfg.cert_manager.install:
                control_plane_cfg.cert_manager.external = click.confirm("Do you want to use an externally provisioned certificate?", default=True)

                if not control_plane_cfg.cert_manager.external:
                    click.echo("Cannot proceed without a certificate")
                    self.error("CERTIFICATE_NOT_PROVIDED")

                if global_cfg.provider == "aws":
                    control_plane_cfg.cert_manager.cert_arn = click.prompt("Please provide the ARN of the certificate to use for the control plane", prompt_suffix="\n")
        else:
            control_plane_cfg.cert_manager.issuer = click.prompt("Please select an existing ClusterIssuer for the control plane. Use new if you want devzero to create a new ClusterIssuer", type=click.Choice(issuers), default=issuers[0])

        control_plane_cfg.save()
        success("Control plane certificates checks done")

    def install_control_plane_cert_manager(self):
        info("Installing control plane certificates...")
        control_plane_cfg = DZConfig().data.control_plane

        if not control_plane_cfg.cert_manager.install and not control_plane_cfg.cert_manager.external and not control_plane_cfg.cert_manager.issuer:
            click.echo("Certificate checks missing. Please run checks first")
            self.error("NOT_READY")

        if control_plane_cfg.cert_manager.install:
            try:
                sh.make("install-cert-manager", _cwd=control_plane_deps_dir)
            except sh.ErrorReturnCode as err:
                click.echo(f"Error installing cert-manager: {err.stderr.decode('utf-8')}", err=True)
                self.error("CERT_MANAGER_INSTALL_FAILED")

        if control_plane_cfg.cert_manager.issuer == "new":
            file = pathlib.Path(f"{control_plane_deps_dir}/values/cluster-issuer.yaml")
            values = yaml.load(file)

            values['spec']['acme']['solvers'][0]['http01']['ingress']['class'] = control_plane_cfg.ingress.cls if control_plane_cfg.ingress.cls not in ["new", ""] else "nginx"

            yaml.dump(values, file)

            try:
                sh.kubectl("apply", "-f", file)
            except sh.ErrorReturnCode as err:
                click.echo(f"Error creating ClusterIssuer: {err.stderr.decode('utf-8')}", err=True)
                self.error("CLUSTER_ISSUER_CREATE_FAILED")

        success("Control plane certificates installed successfully")

    def install_control_plane_deps(self):
        info("Installing control plane dependencies...")
        control_plane_cfg = DZConfig().data.control_plane
        global_cfg = DZConfig().data.globals

        if control_plane_cfg.provision_dbs_in_cluster:
            try:
                sh.make("install-mysql-pulse", _cwd=control_plane_deps_dir)
                sh.make("install-mongodb", _cwd=control_plane_deps_dir)
                sh.make("install-redis", _cwd=control_plane_deps_dir)
                sh.make("install-postgres-logsrv", _cwd=control_plane_deps_dir)
                sh.make("install-postgres-hydra", _cwd=control_plane_deps_dir)
                sh.make("install-postgres-polland", _cwd=control_plane_deps_dir)
                sh.make("install-postgres-vault", _cwd=control_plane_deps_dir)
                sh.make("install-timescaledb-single", _cwd=control_plane_deps_dir)
                sh.make("install-elasticmq", _cwd=control_plane_deps_dir)
            except sh.ErrorReturnCode as err:
                click.echo(f"Error installing databases: {err.stderr.decode('utf-8')}", err=True)
                self.error("DATABASES_INSTALL_FAILED")

        try:
            deps = ["registry", "grafana", "mimir", "vault"]

            for dep in deps:
                file = pathlib.Path(f"{control_plane_deps_dir}/values/{dep}.yaml")
                values = yaml.load(file)

                ingress = values['ingress']

                if dep == "registry":
                    ingress['className'] = control_plane_cfg.ingress.cls if control_plane_cfg.ingress.cls not in ["new", ""] else "nginx"
                else:
                    ingress['ingressClassName'] = control_plane_cfg.ingress.cls if control_plane_cfg.ingress.cls not in ["new", ""] else "nginx"

                if dep == "vault":
                    ingress['hosts'][0]['host'] = f"vault.{global_cfg.domain_name}"
                else:
                    ingress['hosts'][0] = f"{dep}.{global_cfg.domain_name}"

                if control_plane_cfg.cert_manager.external:
                    ingress['tls'] = []
                else:
                    ingress['tls'][0] = {
                        'secretName': f"devzero-{dep}-tls",
                        'hosts': [f"{dep}.{global_cfg.domain_name}"],
                    }

                yaml.dump(values, file)

                sh.make(f"install-{dep}", _cwd=control_plane_deps_dir)
        except sh.ErrorReturnCode as err:
            click.echo(f"Error installing dependencies: {err.stderr.decode('utf-8')}", err=True)
            self.error("DEPS_INSTALL_FAILED")
        success("Control plane dependencies installed successfully")
