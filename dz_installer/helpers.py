import click
import json
import sh

from dz_installer.dz_config import DZConfig


def get_provider():
    cfg = DZConfig()
    if not hasattr(cfg.globals, "provider"):
        import ipdb; ipdb.set_trace(context=10)
        error("MISSING_CLOUD_PROVIDER")

    from dz_installer.providers.aws import AWSProvider
    return AWSProvider()

def error(error_name):
    click.echo(click.style(f"Error code: {error_name}", fg="red"))
    click.get_current_context().exit(1)

def check_chart_is_installed(chart_name, namespace=None):
    # check if helm is installed
    try:
        sh.helm("version")
    except sh.ErrorReturnCode as err:
        click.echo(f"Error checking chart {chart_name}: helm is not installed, please install it first", err=True)
        raise RuntimeError("HELM_NOT_INSTALLED")

    # check if control plane is already installed
    ns = ["-A"]
    if namespace is not None:
        ns = ["-n", namespace]

    click.echo(f"Running command: helm list")
    try:
        output = json.loads(sh.helm(["list", "-o", "json", *ns]))
    except sh.ErrorReturnCode as err:
        click.echo(f"Error running helm list: {err.stderr.decode("utf-8")}", err=True)
        raise RuntimeError("HELM_LIST_FAILED")

    for chart in output:
        if chart['chart'].startswith(chart_name):
            return True
    return False