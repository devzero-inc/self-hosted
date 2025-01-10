#!/bin/bash

REPO_URL="https://${GH_TOKEN}@github.com/devzero-inc/self-hosted.git"
PACKER_DIR="self-hosted/kata/packer"

check_command() {
    command -v "$1" &> /dev/null
}

check_prerequisites() {
    echo "Checking prerequisites..."
    for cmd in git packer aws; do
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

navigate_to_packer_directory() {
    echo "Navigating to the Packer directory..."
    cd "$PACKER_DIR" || { echo "Error: Directory $PACKER_DIR not found."; exit 1; }
}

download_resources() {
    echo "Downloading resources from S3..."
    aws s3 cp s3://dz-pvm-artifacts/ . --recursive

    if [ $? -ne 0 ]; then
        echo "Error: Failed to download resources from S3."
        exit 1
    fi
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
    navigate_to_packer_directory
    download_resources
    initialize_packer
    build_ami
}

main
