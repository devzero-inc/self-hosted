# DevZero Installer (dzi) CLI

The **DevZero Installer (dzi)** CLI is a Python-based command-line tool designed to simplify the installation, configuration, and validation of DevZero self-hosted environments across cloud providers like AWS, GCP, and Azure.

## Prerequisites

- **Python 3**
- **Poetry** (for dependency management)
- **Virtual Environment (venv)**

## Installation

1. **Create and Activate Virtual Environment:**

```bash
python3 -m venv venv
source venv/bin/activate
```

2. **Install Dependencies:**

```bash
poetry install
```

## Usage

Run the CLI using:

```bash
./dzi --help
```

### General Options:
- `--version` : Displays the version of the CLI.
- `--help`    : Provides command usage details.

## Commands

### 1. **Global Configuration**

Configure global settings like the cloud provider:

```bash
./dzi global-config cloud-provider {aws|gcp|azure}
```

Example:

```bash
./dzi global-config cloud-provider aws
```

### 2. **Check**

Verify the environment prerequisites before installation:

```bash
./dzi check --help
```

#### Subcommands:
- **Control Plane Checks:**
  ```bash
  ./dzi check control-plane all
  ./dzi check control-plane permissions
  ./dzi check control-plane cluster
  ./dzi check control-plane network
  ./dzi check control-plane ingress
  ./dzi check control-plane chart
  ./dzi check control-plane certificates
  ```

- **Data Plane Checks:**
  ```bash
  ./dzi check data-plane all
  ./dzi check data-plane permissions
  ./dzi check data-plane network
  ./dzi check data-plane cluster
  ./dzi check data-plane ingress
  ./dzi check data-plane rook-ceph
  ./dzi check data-plane prometheus
  ```

### 3. **Install**

Install various DevZero components:

```bash
./dzi install --help
```

#### Subcommands:
- **Control Plane Installation:**
  ```bash
  ./dzi install control-plane all
  ./dzi install control-plane ingress
  ./dzi install control-plane certificate
  ./dzi install control-plane deps
  ./dzi install control-plane chart
  ```

- **Data Plane Installation:**
  ```bash
  ./dzi install data-plane all
  ./dzi install data-plane rook-ceph
  ./dzi install data-plane prometheus
  ```

## Example Workflow

1. **Activate the Virtual Environment:**
   ```bash
   source venv/bin/activate
   ```

2. **Configure Cloud Provider:**
   ```bash
   ./dzi global-config cloud-provider aws
   ```

3. **Run Environment Checks:**
   ```bash
   ./dzi check control-plane all
   ./dzi check data-plane all
   ```

4. **Install DevZero Components:**
   ```bash
   ./dzi install control-plane all
   ./dzi install data-plane all
   ```

## Troubleshooting

- Use `--help` with any command to get more information.
- Verify that the virtual environment is activated.
- Ensure all dependencies are installed via `poetry install`.