import click
import re
from typing import Any
from subprocess import STDOUT, CalledProcessError, check_output, run

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

def _space_split(output_line: str):
    return [value for value in re.split(r"(\t|  +)", output_line) if not re.match(r"^\s*$", value)]


def _get_name_locations(names: list[str], name_string: str):
    locs: list[Any] = []
    last_pos = 0
    for name in names:
        last_pos = name_string.find(name, last_pos)
        locs.append(last_pos)
    for i, loc in enumerate(locs):
        if i + 1 < len(locs):
            locs[i] = (loc, locs[i + 1])
            continue
        locs[i] = (loc, len(name_string))
    return locs


def _split_using_locations(locations: list[tuple[int, int]], values_string: str):
    vals = []
    for i, loc in enumerate(locations):
        start = loc[0]
        end = loc[1]
        if i == len(locations) - 1:
            vals.append(values_string[start:].strip())
            continue
        vals.append(values_string[start:end].strip())
    return vals


def _parse_helm_list_output_to_dict(output: str):
    output_lines = output.split("\n")
    names = _space_split(output_lines[0])
    value_locations = _get_name_locations(names, output_lines[0])
    value_rows = []
    for line in output_lines[1:]:
        if line.strip():
            values = _split_using_locations(value_locations, line)
            value_rows.append(values)
    return {names[i]: row for i, row in enumerate(zip(*value_rows))}

def check_chart_is_installed(chart_name, namespace=None):
    # check if helm is installed
    command = "helm version"
    try:
        run(command.split(" "), stderr=STDOUT)
    except CalledProcessError as err:
        click.echo(f"Error checking chart {chart_name}: helm is not installed, please install it first", err=True)
        raise RuntimeError("HELM_NOT_INSTALLED")

    # check if control plane is already installed
    command = "helm list -A"
    if namespace is not None:
        command = f"helm list -n {namespace}"

    click.echo(f"Running command: {command}")
    try:
        output = check_output(command.split(" "), stderr=STDOUT).decode("utf-8")
    except CalledProcessError as err:
        click.echo(f"Error running command {command}: {err.output.decode("utf-8")}", err=True)
        raise RuntimeError("HELM_LIST_FAILED")

    installed_charts = _parse_helm_list_output_to_dict(output)['CHART']

    for chart in installed_charts:
        if chart.startswith(chart_name):
            return True
    return False