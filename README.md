# DevZero Self Hosted Configuration

TODO: Improve readme

## CLI Installation

1. Install the CLI dependencies
    ```bash
    poetry install
    ```

2. Set your cloud provider in the global configuration (aws, azure, gcp)
    ```bash
    ./dzi global-config cloud-provider <cloud-provider>
    ```
    
3. Run the control plane checks
    ```bash
    ./dzi check control-plane all
    ```
