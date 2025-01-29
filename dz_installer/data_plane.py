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

        # Store the information in CLI state file
        cfg.save()
        success("Data Plane Prometheus checks")
