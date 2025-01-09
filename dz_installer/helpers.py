import click

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