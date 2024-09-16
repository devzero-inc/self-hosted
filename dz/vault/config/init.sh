#!/bin/sh

echo "Waiting for Vault to be ready..."

# Wait until Vault is initialized
sleep 5

echo "Vault is ready. Initializing the KV engine..."

# Set the root token
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=root

# Enable KV secrets engine at the path "devzero"
vault secrets enable -path=devzero kv

echo "KV secrets engine 'devzero' initialized."
