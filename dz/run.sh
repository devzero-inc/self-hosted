#!/bin/bash

set -euo pipefail

DOCKER_COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
EXAMPLE_ENV_FILE=".env.example"
ARM_ENV_FILE=".env.arm64"
AMD_ENV_FILE=".env.amd64"
CONTAINER_NAME="hydra"
API_KEY_VAR="HYDRA_API_KEY"
LICENSE_KEY_VAR="LICENSE_KEY"
RELOAD=false
BACKEND_CONTAINER_NAME="backend"
LICENSE_ERROR="Error verifying license token"
REGISTRY_URL="056855531191.dkr.ecr.us-west-2.amazonaws.com"
LOCAL_REGISTRY_URL="localhost:5959"
TEMP_TOKEN_FILE="./docker.txt"
KUBECONFIG_FILE="../kubeconfig"
IMAGES_DIR="./images"

# Parse arguments for reload flag
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --reload) RELOAD=true ;;
        *) printf "Unknown parameter passed: %s\n" "$1" >&2; exit 1 ;;
    esac
    shift
done

# Ensure that docker-compose file exists
if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
    printf "Docker compose file %s not found.\n" "$DOCKER_COMPOSE_FILE" >&2
    exit 1
fi

# Detect system architecture (arm64 or amd64)
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    ARCH_ENV_FILE="$AMD_ENV_FILE"
    ARCH_TYPE="amd64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    ARCH_ENV_FILE="$ARM_ENV_FILE"
    ARCH_TYPE="arm64"
else
    printf "Unsupported architecture: %s\n" "$ARCH" >&2
    exit 1
fi

# Check if .env file exists, skip copying if it does
if [[ -f "$ENV_FILE" ]]; then
    printf "%s already exists. Skipping copy.\n" "$ENV_FILE"
else
    # Ensure that the appropriate architecture-specific .env file exists, and copy it to .env
    if [[ -f "$ARCH_ENV_FILE" ]]; then
        cp "$ARCH_ENV_FILE" "$ENV_FILE"
        printf "Copied %s to %s\n" "$ARCH_ENV_FILE" "$ENV_FILE"
    elif [[ -f "$EXAMPLE_ENV_FILE" ]]; then
        cp "$EXAMPLE_ENV_FILE" "$ENV_FILE"
        printf "Copied %s to %s\n" "$EXAMPLE_ENV_FILE" "$ENV_FILE"
    else
        printf "Neither %s nor %s found. Exiting.\n" "$ARCH_ENV_FILE" "$EXAMPLE_ENV_FILE" >&2
        exit 1
    fi
fi

# Function to check if a variable is already set in the .env file
is_env_var_set() {
    local var_name="$1"
    grep -q "^${var_name}=" "$ENV_FILE" && grep -q "^${var_name}=[^ ]\+$" "$ENV_FILE"
}

# Function to prompt the user for the license key and inject it into the .env file
prompt_for_license_key() {
    if ! is_env_var_set "$LICENSE_KEY_VAR"; then
        printf "License key not found in .env file.\n"
        printf "Please enter your license key: "
        read -r license_key
        if [[ -z "$license_key" ]]; then
            printf "No license key provided. Exiting.\n" >&2
            exit 1
        fi
        printf "%s=%s\n" "$LICENSE_KEY_VAR" "$license_key" >> "$ENV_FILE"
    fi
}

# Function to check if the user is logged in to the Docker registry
check_registry_login() {
    if ! docker system info --format '{{json .RegistryConfig.IndexConfigs}}' | grep -q "$REGISTRY_URL"; then
        printf "You are not logged into the Docker registry: %s\n" "$REGISTRY_URL"
        prompt_for_registry_login
    else
        printf "Already logged into the Docker registry: %s\n" "$REGISTRY_URL"
    fi
}

# Function to load and push images based on the architecture
load_and_push_images_to_local_registry() {
    if [[ ! -d "$IMAGES_DIR" ]]; then
        printf "Images directory %s not found.\n" "$IMAGES_DIR" >&2
        exit 1
    fi

    for image_tar in "$IMAGES_DIR"/*_"$ARCH_TYPE".tar; do
        if [[ -f "$image_tar" ]]; then
            printf "Loading image from %s\n" "$image_tar"

            # Optionally, remove any existing images for this tag to ensure a clean load
            docker image prune -a --force

            # Load image from tar file
            docker load -i "$image_tar"
            
            # Extract image name from the loaded image
            image_name=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep "$ARCH_TYPE" | head -n 1)

            if [[ -z "$image_name" ]]; then
                printf "No matching image found for architecture %s.\n" "$ARCH_TYPE" >&2
                exit 1
            fi

            # Tag and push the image to the local registry
            printf "Tagging and pushing %s to local registry %s\n" "$image_name" "$LOCAL_REGISTRY_URL"
            docker tag "$image_name" "$LOCAL_REGISTRY_URL/$image_name"
            docker push "$LOCAL_REGISTRY_URL/$image_name"
        else
            printf "No images found for architecture %s in %s\n" "$ARCH_TYPE" "$IMAGES_DIR" >&2
            exit 1
        fi
    done
    printf "All images for %s have been loaded and pushed to the local registry.\n" "$ARCH_TYPE"
}

# Function to prompt the user for Docker registry credentials and log them in
prompt_for_registry_login() {
    # If docker.txt exists and has content, use it directly
    if [[ -f "$TEMP_TOKEN_FILE" && -s "$TEMP_TOKEN_FILE" ]]; then
        printf "Using existing token from %s\n" "$TEMP_TOKEN_FILE"
        registry_token=$(<"$TEMP_TOKEN_FILE")
    else
        printf "Please paste your Docker registry token into the following file and save it:\n"
        printf "%s\n" "$TEMP_TOKEN_FILE"
        read -p "Press Enter when done..."
        if ! registry_token=$(<"$TEMP_TOKEN_FILE"); then
            printf "Failed to read the registry token from the file. Exiting.\n" >&2
            exit 1
        fi
    fi
    
    # Perform Docker login
    if [[ -z "$registry_token" ]]; then
        printf "No registry token provided. Exiting.\n" >&2
        exit 1
    fi
    if ! echo "$registry_token" | docker login --username AWS --password-stdin "$REGISTRY_URL"; then
        printf "Docker registry login failed. Exiting.\n" >&2
        exit 1
    fi
    printf "Successfully logged into Docker registry: %s\n" "$REGISTRY_URL"
}

# Function to start docker-compose and wait until services are up
start_docker_compose() {
    docker compose up -d

    # Wait until the hydra container is healthy
    wait_for_container_healthy() {
        local container="$1"
        local retries=10
        local wait=5
        for ((i=0; i<retries; i++)); do
            if [[ $(docker inspect --format='{{.State.Health.Status}}' "$container") == "healthy" ]]; then
                return 0
            fi
            printf "Waiting for container %s to become healthy...\n" "$container"
            sleep "$wait"
        done
        printf "Container %s did not become healthy in time.\n" "$container" >&2
        return 1
    }

    if ! wait_for_container_healthy "$CONTAINER_NAME"; then
        exit 1
    fi
}

# Function to create API key and inject it into .env
create_and_inject_api_key() {
    # Run the command inside the "hydra" container and capture the output
    if ! output=$(docker exec "$CONTAINER_NAME" /bin/bash -c "headscale apikeys create"); then
        printf "Failed to run the API key creation command inside %s container.\n" "$CONTAINER_NAME" >&2
        exit 1
    fi

    # Extract the key from the output
    api_key=$(echo "$output" | awk NF | tail -n 1)
    if [[ -z "$api_key" ]]; then
        printf "Failed to extract the API key from the output.\n" >&2
        exit 1
    fi
    printf "API Key generated: %s\n" "$api_key"

    # Inject the API key into the .env file
    sed -i.bak "s/^${API_KEY_VAR}=.*/${API_KEY_VAR}=${api_key}/" "$ENV_FILE"
}

# Function to check for license errors in the backend service logs
check_license_error() {
    if docker logs "$BACKEND_CONTAINER_NAME" 2>&1 | grep -q "$LICENSE_ERROR"; then
        printf "License key validation failed: %s\n" "$LICENSE_ERROR" >&2
        docker compose down
        exit 1
    fi
}

# Function to create the cluster in Poland
create_cluster_in_poland() {
    # Extract data from the kubeconfig file
    local certificate_authority_data token
    certificate_authority_data=$(yq e '.clusters[0].cluster."certificate-authority-data"' "$KUBECONFIG_FILE")
    
    if ! token=$(kubectl get secret devzero-sa0-token -n default -o jsonpath='{.data.token}' --kubeconfig "$KUBECONFIG_FILE" | base64 -d); then
        printf "Failed to retrieve service account token.\n" >&2
        return 1
    fi

    # Determine the correct server based on the OS
    local server_address
    if [[ "$(uname)" == "Darwin" ]]; then
        server_address="https://host.docker.internal:8443"
    else
        # Assuming Linux will use 172.17.0.1, you can adjust this IP if needed
        server_address="https://172.17.0.1:8443"
    fi

    # Run the commands to set up the cluster in Poland
    printf "Creating devzero user.\n" >&2
    docker compose -f ./docker-compose.yml run polland /wait-for-it.sh -- ./manage.py createsuperuser --email devzero@devzero.io --noinput || true
    
    printf "Setting password for superuser.\n" >&2
    docker compose -f ./docker-compose.yml run polland ./manage.py shell_plus -c 'user = User.objects.get(email="devzero@devzero.io"); user.set_password("123123"); user.save();' || true
    
    printf "Creating cluster object.\n" >&2
    docker compose -f ./docker-compose.yml run polland ./manage.py shell_plus -c "
from django.db.utils import IntegrityError
from polland.clusters.models.cluster import Cluster

try:
    cluster, created = Cluster.objects.get_or_create(
        cluster_id=1,
        defaults={
            'name': 'minikube',
            'certificate_authority_data': \"$certificate_authority_data\",
            'server': \"$server_address\",
            'service_account_name': 'devzero-sa0',
            'service_account_token': \"$token\",
            'slug': 'minikube'
        }
    )
    if not created:
        cluster.name = 'minikube'
        cluster.certificate_authority_data = \"$certificate_authority_data\"
        cluster.server = \"$server_address\"
        cluster.service_account_name = 'devzero-sa0'
        cluster.service_account_token = \"$token\"
        cluster.slug = 'minikube'
        cluster.save()
except IntegrityError:
    pass
"
}

# Main execution logic
main() {
    # Check if the user is logged into the Docker registry
    check_registry_login

    # Prompt for license key if not already set
    prompt_for_license_key

    if is_env_var_set "$API_KEY_VAR" && [[ "$RELOAD" = false ]]; then
        printf "API Key is already set. Skipping API key generation and injection.\n"
        docker compose up -d
    else
        printf "Starting the API key generation and injection process...\n"
        docker compose down
        start_docker_compose
        create_and_inject_api_key
        docker compose down
        docker compose up -d
        # Clean up the backup .env file
        rm -f "${ENV_FILE}.bak"
    fi

    # Check for license errors in the backend service logs
    printf "Checking backend service for license validation...\n"
    check_license_error

    # Create the cluster in Poland
    printf "Creating the cluster in Poland...\n"
    create_cluster_in_poland

    printf "Docker setup complete.\n"

    printf "Loading image to local registry...\n"
    # Load and push images to the local registry
    load_and_push_images_to_local_registry
    printf "Image load complete.\n"
}

main
