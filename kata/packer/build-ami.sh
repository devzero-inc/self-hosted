#!/bin/bash

REPO_URL="https://${GH_TOKEN}@github.com/devzero-inc/self-hosted.git"
PACKER_DIR="self-hosted/kata/packer"
LINUX_IMAGES_DIR="self-hosted/kata/linux-images"
DOCKER_CONTAINER_HOST="linux-image-host"
DOCKER_CONTAINER_GUEST="linux-image-guest"

check_command() {
    command -v "$1" &> /dev/null
}

check_prerequisites() {
    echo "Checking prerequisites..."
    for cmd in git docker packer aws; do
        if ! check_command "$cmd"; then
            echo "Error: $cmd is not installed. Please install $cmd and try again."
            exit 1
        fi
    done
    echo "All prerequisites are installed."
}

clone_repository() {
    echo "Cloning the repository..."
    git clone "$REPO_URL"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone the repository."
        exit 1
    fi
}

navigate_to_linux_images_directory() {
    echo "Navigating to the Linux images directory..."
    cd "$LINUX_IMAGES_DIR" || { echo "Error: Directory $LINUX_IMAGES_DIR not found."; exit 1; }
    git clone https://github.com/virt-pvm/linux.git --depth=1
}

build_docker_containers() {
    echo "Building the Docker container for the host..."
    docker build -t "$DOCKER_CONTAINER_HOST" -f Dockerfile.host .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build the host Docker container."
        exit 1
    fi

    echo "Running the host Docker container..."
    docker run -d --name "$DOCKER_CONTAINER_HOST" "$DOCKER_CONTAINER_HOST"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to run the host Docker container."
        exit 1
    fi

    echo "Copying host package files to the Packer directory..."
    docker cp "$DOCKER_CONTAINER_HOST:/kernel-6.7.0_dz_pvm_host-1.x86_64.rpm" "$PACKER_DIR/kernel.rpm"
    docker cp "$DOCKER_CONTAINER_HOST:/kernel-headers-6.7.0_dz_pvm_host-1.x86_64.rpm" "$PACKER_DIR/kernel-headers.rpm"
    docker cp "$DOCKER_CONTAINER_HOST:/kernel-devel-6.7.0_dz_pvm_host-1.x86_64.rpm" "$PACKER_DIR/kernel-devel.rpm"

    echo "Building the Docker container for the guest..."
    docker build -t "$DOCKER_CONTAINER_GUEST" -f Dockerfile.guest .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build the guest Docker container."
        exit 1
    fi

    echo "Running the guest Docker container..."
    docker run -d --name "$DOCKER_CONTAINER_GUEST" "$DOCKER_CONTAINER_GUEST"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to run the guest Docker container."
        exit 1
    fi

    echo "Copying guest vmlinux file to the Packer directory..."
    docker cp "$DOCKER_CONTAINER_GUEST:/guest-vmlinux" "$PACKER_DIR"
}

navigate_to_packer_directory() {
    echo "Navigating to the Packer directory..."
    cd "$PACKER_DIR" || { echo "Error: Directory $PACKER_DIR not found."; exit 1; }
}

initialize_packer() {
    echo "Initializing Packer..."
    packer init .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to initialize Packer."
        exit 1
    fi
}

build_ami() {
    echo "Building the AMI with Packer..."
    packer build .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build the AMI."
        exit 1
    fi
    echo "AMI build process completed successfully!"
}

main() {
    check_prerequisites
    clone_repository
    navigate_to_linux_images_directory
    build_docker_containers
    navigate_to_packer_directory
    initialize_packer
    build_ami
}

main
