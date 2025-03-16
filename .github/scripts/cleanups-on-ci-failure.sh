#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Find the Git repository root directory
find_repo_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.git" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  
  echo "Error: Could not find repository root. Make sure you're running this script from within a Git repository."
  exit 1
}

# check if AWS CLI is available
if ! command_exists aws; then
  echo "Error: AWS CLI is not installed. Please install it and try again."
  exit 1
fi

# check if Git is available (for finding repo root)
if ! command_exists git; then
  echo "Error: Git is not installed. Please install it and try again."
  exit 1
fi

# check if Terraform is available
if ! command_exists terraform; then
  echo "Error: Terraform is not installed. Please install it and try again."
  exit 1
fi

# check if kubectl is available
if ! command_exists kubectl; then
  echo "Warning: kubectl is not installed - needed for Kubernetes resource cleanup."
  exit 1
fi

# check if jq is available (for JSON parsing)
if ! command_exists jq; then
  echo "Warning: jq is not installed. It's recommended for better error handling."
fi

# AWS environment variables that might interfere with AWS CLI
AWS_ENV_VARS=(
  "AWS_ACCESS_KEY_ID"
  "AWS_SECRET_ACCESS_KEY"
  "AWS_SESSION_TOKEN"
  "AWS_SECURITY_TOKEN"
  "AWS_DEFAULT_REGION"
)

ENV_VARS_SET=false
for var in "${AWS_ENV_VARS[@]}"; do
  if [ -n "${!var}" ]; then
    echo "Warning: $var is set, which may interfere with AWS SSO login."
    ENV_VARS_SET=true
  fi
done

if [ "$ENV_VARS_SET" = true ]; then
  echo "Please unset these variables before continuing or they may interfere with the AWS profile."
  read -p "Do you want to continue anyway? (y/n): " continue_anyway
  if [ "$continue_anyway" != "y" ] && [ "$continue_anyway" != "Y" ]; then
    echo "Exiting script. Please unset the environment variables and try again."
    exit 1
  fi
  echo "Continuing with environment variables set..."
else
  echo "No interfering AWS environment variables detected."
fi

# AWS profile self-hosted and us-west-1 (that's where all the test infra is spun up)
export AWS_PROFILE=self-hosted
echo "AWS profile set to: $AWS_PROFILE"

# AWS SSO login ....
echo "Performing AWS SSO login..."
aws sso login --sso-session devzero --profile $AWS_PROFILE
if [ $? -ne 0 ]; then
  echo "Error: AWS SSO login failed. Please try again."
  exit 1
fi

# S3 bucket for terraform state
S3_BUCKET="dsh-tf-state"
echo "Using S3 bucket: $S3_BUCKET"

export AWS_REGION=us-west-1
echo "AWS region set to: $AWS_REGION"

# find self-hosted repository root
REPO_ROOT=$(find_repo_root)
echo "Repository root found at: $REPO_ROOT"

# define terraform state paths relative to repo root
BASE_CLUSTER_PATH="$REPO_ROOT/terraform/examples/aws/base-cluster"
CLUSTER_EXTENSIONS_PATH="$REPO_ROOT/terraform/examples/aws/cluster-extensions"

# Verify terraform directories exist
if [ ! -d "$BASE_CLUSTER_PATH" ]; then
  echo "Error: Base cluster directory '$BASE_CLUSTER_PATH' does not exist."
  exit 1
fi

if [ ! -d "$CLUSTER_EXTENSIONS_PATH" ]; then
  echo "Error: Cluster extensions directory '$CLUSTER_EXTENSIONS_PATH' does not exist."
  exit 1
fi

echo "Terraform directories verified."

# check and clean up existing state files
check_and_clean_tfstate() {
  local dir="$1"
  local files_exist=false
  
  # Check for any terraform state files
  if ls "$dir"/terraform.tfstate* 2>/dev/null || ls "$dir"/.terraform.lock.hcl 2>/dev/null || [ -d "$dir"/.terraform ]; then
    echo "Existing Terraform state files found in: $dir"
    ls -la "$dir"/terraform.tfstate* "$dir"/.terraform.lock.hcl 2>/dev/null
    if [ -d "$dir/.terraform" ]; then
      echo "Directory $dir/.terraform exists"
    fi
    files_exist=true
  fi
  
  if [ "$files_exist" = true ]; then
    read -p "Do you want to clean up these files before downloading? (y/n): " cleanup
    if [ "$cleanup" = "y" ] || [ "$cleanup" = "Y" ]; then
      echo "Removing Terraform state files from $dir"
      rm -f "$dir"/terraform.tfstate*
      rm -f "$dir"/.terraform.lock.hcl
      rm -rf "$dir"/.terraform
      echo "Cleanup complete."
    else
      echo "Warning: Existing files may be overwritten or cause conflicts."
    fi
  else
    echo "No existing Terraform state files found in: $dir"
  fi
}

# Function to configure kubectl for a cluster
configure_kubectl() {
  local cluster_name="$1"
  
  echo "Configuring kubectl for cluster: $cluster_name"
  
  # Update kubeconfig for the cluster
  aws eks update-kubeconfig --name "$cluster_name" --profile "$AWS_PROFILE" --region "$AWS_REGION"
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to update kubeconfig for cluster $cluster_name"
    return 1
  fi

  aws eks create-access-entry --cluster-name "$cluster_name" --profile "$AWS_PROFILE" --region "$AWS_REGION" --principal-arn arn:aws:iam::484907513542:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_AWSAdministratorAccess_cdb3218a34dc613b --type STANDARD
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to create access-entry for cluster $cluster_name"
    return 1
  fi

  aws eks associate-access-policy --cluster-name "$cluster_name" --profile "$AWS_PROFILE" --region "$AWS_REGION" --principal-arn arn:aws:iam::484907513542:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_AWSAdministratorAccess_cdb3218a34dc613b --access-scope type=cluster --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to associate policy with access-entry for cluster $cluster_name"
    return 1
  fi

  # Test kubectl connection
  echo "Testing kubectl connection..."
  kubectl get nodes
  if [ $? -ne 0 ]; then
    echo "Warning: kubectl cannot connect to cluster $cluster_name"
    return 1
  fi
  
  echo "Successfully configured kubectl for cluster $cluster_name"
  return 0
}

# Function to run terraform destroy with explicit variable
run_terraform_destroy() {
  local dir="$1"
  local name="$2"
  local cluster_name="$3"
  
  echo "=== Running terraform destroy in $name ==="
  
  # Change to the directory and run terraform destroy
  cd "$dir"
  
  # Initialize terraform if needed
  echo "Initializing Terraform..."
  terraform init
  if [ $? -ne 0 ]; then
    echo "Error: Terraform init failed in $name."
    return 1
  fi
  
  # Run terraform plan to see what would be destroyed
  echo "Running terraform plan with explicit cluster_name=\"$cluster_name\"..."
  terraform plan -destroy -var="cluster_name=$cluster_name"
  
  # Confirm before destroying
  read -p "Do you want to proceed with terraform destroy? (y/n): " proceed
  if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
    echo "Skipping destroy operation."
    return 0
  fi
  
  # Run terraform destroy with explicit variable
  echo "Running terraform destroy with explicit cluster_name=\"$cluster_name\"..."
  terraform destroy -auto-approve -var="cluster_name=$cluster_name"
  if [ $? -ne 0 ]; then
    echo "Error: Terraform destroy failed in $name."
    return 1
  fi
  
  echo "Successfully destroyed resources in $name."
  return 0
}

# get list of failed job identifiers from user
echo "Enter a comma-separated list of job identifiers to process (check env_var 'JOB_IDENTIFIER' in a failed GitHub Action workflow run; e.g.: 'gh-1-30-al2023-c74f'):"
read -r dir_list

# convert comma-separated list to array cuz loop
IFS=',' read -ra DIRS <<< "$dir_list"

# Track overall success
CLEANUP_SUCCESS=true

# Process each job identifier
for dir in "${DIRS[@]}"; do
  # trim whitespace cuz user's input random shit
  dir=$(echo "$dir" | xargs)
  echo "=========================================================="
  echo "Processing job identifier: $dir"
  echo "=========================================================="
  
  # Process cluster-extensions first (child resources)
  echo "Working on cluster-extensions..."
  
  # Check and clean up cluster-extensions directory
  echo "Checking cluster-extensions directory for existing state files..."
  check_and_clean_tfstate "$CLUSTER_EXTENSIONS_PATH"
  
  # pull terraform.tfstate for cluster-extensions
  echo "Downloading terraform state for $dir/cluster-extensions"
  aws s3 cp "s3://$S3_BUCKET/$dir/cluster-extensions/terraform.tfstate" "$CLUSTER_EXTENSIONS_PATH/terraform.tfstate"
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to download terraform.tfstate for $dir/cluster-extensions"
    CLEANUP_SUCCESS=false
  else
    echo "Successfully downloaded terraform.tfstate for $dir/cluster-extensions"
    
    # Check and clean up any existing .terraform directory
    if [ -d "$CLUSTER_EXTENSIONS_PATH/.terraform" ]; then
      echo "Removing existing .terraform directory to ensure clean initialization..."
      rm -rf "$CLUSTER_EXTENSIONS_PATH/.terraform"
    fi
    
    # configure kubectl for this cluster
    configure_kubectl "$dir"
    
    # run terraform destroy for cluster-extensions
    if ! run_terraform_destroy "$CLUSTER_EXTENSIONS_PATH" "cluster-extensions" "$dir"; then
      CLEANUP_SUCCESS=false
    fi
  fi
  
  # Now process base-cluster (parent resources)
  echo "Working on base-cluster..."
  
  # Check and clean up base-cluster directory
  echo "Checking base-cluster directory for existing state files..."
  check_and_clean_tfstate "$BASE_CLUSTER_PATH"
  
  # pull terraform.tfstate for base-cluster
  echo "Downloading terraform state for $dir/base-cluster"
  aws s3 cp "s3://$S3_BUCKET/$dir/base-cluster/terraform.tfstate" "$BASE_CLUSTER_PATH/terraform.tfstate"
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to download terraform.tfstate for $dir/base-cluster"
    CLEANUP_SUCCESS=false
  else
    echo "Successfully downloaded terraform.tfstate for $dir/base-cluster"
    
    # Check and clean up any existing .terraform directory
    if [ -d "$BASE_CLUSTER_PATH/.terraform" ]; then
      echo "Removing existing .terraform directory to ensure clean initialization..."
      rm -rf "$BASE_CLUSTER_PATH/.terraform"
    fi
    
    # Run terraform destroy for base-cluster
    if ! run_terraform_destroy "$BASE_CLUSTER_PATH" "base-cluster" "$dir"; then
      CLEANUP_SUCCESS=false
    fi
  fi
  
  echo "Completed processing job identifier: $dir"
  echo "----------------------------------------------------------"
done

# Return to the original directory
cd "$REPO_ROOT"

# Final status report
echo ""
echo "=========================================================="
if [ "$CLEANUP_SUCCESS" = true ]; then
  echo "✅ All cleanup operations completed successfully!"
else
  echo "⚠️ Some cleanup operations failed. Please check the logs above for details."
  echo "You may need to manually inspect and clean up some resources."
fi
echo "=========================================================="
