#!/bin/sh

# Wait for Vault to be up
while ! curl -s http://127.0.0.1:8200/v1/sys/health > /dev/null; do
  echo "Waiting for Vault to start..."
  sleep 2
done

echo "Vault is up! Checking initialization status..."

# Check if Vault is already initialized
INIT_STATUS=$(curl -s http://127.0.0.1:8200/v1/sys/init | jq -r .initialized)

if [ "$INIT_STATUS" = "false" ]; then
  echo "Initializing Vault..."
  INIT_RESPONSE=$(curl -s --request POST --data '{"secret_shares": 1, "secret_threshold": 1}' http://127.0.0.1:8200/v1/sys/init)
  UNSEAL_KEY=$(echo $INIT_RESPONSE | jq -r .keys[0])
  echo "Vault initialized with unseal key: $UNSEAL_KEY"
else
  echo "Vault is already initialized. Retrieving unseal key..."
  UNSEAL_KEY="ZGV2emVyby11bnNlYWwtMw==" 
fi

# Unseal Vault
echo "Unsealing Vault..."
curl --request POST --data "{\"key\": \"$UNSEAL_KEY\"}" http://127.0.0.1:8200/v1/sys/unseal

echo "Vault unsealed!"
