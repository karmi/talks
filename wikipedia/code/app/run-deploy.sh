#!/usr/bin/env bash

# Documentation: https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-service

set -e

env_vars=(ELASTICSEARCH_URL ELASTICSEARCH_USER ELASTICSEARCH_PASSWORD INFERENCE_API_TOKEN)
env_vars_string=""

for var in "${env_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "[!] Variable $var is not set"; exit 1
  else
    env_vars_string="${env_vars_string}${var}=${!var},"
  fi
done

gcloud run deploy \
  wikipedia-search \
  --description='Semantic search for Wikipedia' \
  --set-env-vars="$env_vars_string" \
  --source=. \
  --cpu=1 \
  --memory=1G \
  --max-instances=5 \
  --allow-unauthenticated \
  --region=europe-west1
