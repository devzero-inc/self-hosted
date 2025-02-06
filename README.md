# DevZero Self-Hosted

Welcome to the **self-hosted** repository. This repository contains all the necessary components for setting up and managing a self-hosted environment, including infrastructure as code, deployment configurations, and custom tooling.

## Repository Structure

```bash
self-hosted/
├── kata/
├── terraform/
├── charts/
├── dz_installer/
└── README.md
```

### 1. **kata/**
- **Description:** Used to create Amazon Machine Images (AMIs) required in the infrastructure for setting up Kubernetes nodes with Kata as the default `RuntimeClass`.
- **Usage:** Build and manage AMIs optimised for secure and efficient Kubernetes workloads using Kata Containers.
- **More Info:** [kata/README.md](./kata/README.md)

### 2. **terraform/**
- **Description:** Contains Infrastructure as Code (IaC) scripts to provision the required infrastructure on cloud platforms such as AWS, GCP, and Azure for self-hosting the DevZero Control Plane and Data Plane.
- **Usage:** Deploy and manage scalable infrastructure tailored for DevZero’s self-hosted architecture.
- **More Info:** [terraform/README.md](./terraform/README.md)

### 3. **charts/**
- **Description:** Contains Helm charts used to package, configure, and deploy the DevZero Control Plane and Data Plane.
- **Usage:** Utilise Helm to streamline Kubernetes application deployments, ensuring consistent and repeatable configurations.
- **More Info:** [charts/README.md](./charts/README.md)

### 4. **dz-installer/**
- **Description:** A Python CLI tool designed for easy requirement checks, installation, and validation of DevZero self-hosted environments based on user-specific requirements.
- **Usage:** Simplify the setup process by automating environment validation and installation workflows through interactive user inputs.
- **More Info:** [dz-installer/README.md](./dz-installer/README.md)

## How They Fit Together

- **kata** builds the custom AMIs required for Kubernetes nodes, optimised with Kata Containers as the default runtime.
- **terraform** provisions the infrastructure across different cloud providers to support both the Control Plane and Data Plane of DevZero.
- **charts** deploys the DevZero Control Plane and Data Plane onto the infrastructure provisioned by Terraform.
- **dz-installer** ensures seamless installation and validation of the self-hosted setup, guiding users through configuration and deployment steps.

## Getting Started

1. **Build AMIs:**
   - Use the `kata/` directory to create the AMIs required for Kubernetes nodes. If you prefer to skip building custom Kata AMIs, you can proceed directly to provisioning infrastructure. The Terraform scripts are configured to use the public Kata AMIs created by DevZero.

2. **Provision Infrastructure:**
   - Navigate to the `terraform/` folder and follow the instructions to deploy the necessary cloud infrastructure. 

3. **Deploy Applications:**
   - Deploy the DevZero Control Plane and Data Plane using Helm charts from the `charts/` directory.

4. **Automate Setup:**
   - Leverage the `dz-installer/` Python CLI to check prerequisites, install components, and validate the environment.

For detailed instructions, refer to the specific README files within each folder.


