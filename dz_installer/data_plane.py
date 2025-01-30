from kubernetes import client, config
from dz_installer.dz_config import DZConfig
from dz_installer.helpers import info, success, error, check_chart_is_installed
import click

class DataPlane:
    @staticmethod
    def check_data_plane_prometheus(force):
        """Check if the Prometheus Helm chart is installed and prompt for installation if missing."""
        info("Checking Prometheus installation in the data plane...")

        chart_name = "prometheus"
        cfg = DZConfig().data

        if cfg.data_plane.prometheus_installed and not force:
            click.echo("Prometheus is already installed. Skipping check...")
            return

        try:
            if check_chart_is_installed(chart_name):
                success("Prometheus chart is installed.")
                cfg.data_plane.prometheus_installed = True
            else:
                click.echo("Prometheus chart is not installed.")
                install = click.confirm("Do you want to install Prometheus?", default=True)
                if not install:
                    click.echo("Cannot proceed without Prometheus.")
                    return
        except RuntimeError as e:
            error(f"Error checking Prometheus chart: {e}")
            return

        cfg.save()
        success("Data Plane Prometheus checks")


    @staticmethod
    def check_data_plane_rook_ceph(force):
        """Check if the Rook-Ceph Helm chart is installed, check its version, and store the status in the CLI state file."""
        info("Checking Rook-Ceph installation in the data plane...")

        chart_name = "rook-ceph"
        cfg = DZConfig().data

        if cfg.data_plane.rook_ceph_installed and not force:
            click.echo("Rook-Ceph is already installed. Skipping check...")
            return

        try:
            if check_chart_is_installed(chart_name):
                success("Rook-Ceph chart is installed.")
                cfg.data_plane.rook_ceph_installed = True
            else:
                click.echo("Rook-Ceph chart is not installed.")
                install = click.confirm("Do you want to install Rook-Ceph?", default=True)
                if not install:
                    click.echo("Cannot proceed without Rook-Ceph.")
                    return
        except RuntimeError as e:
            error(f"Error checking Rook-Ceph chart: {e}")
            return

        cfg.save()
        success("Data Plane Rook-Ceph checks")


