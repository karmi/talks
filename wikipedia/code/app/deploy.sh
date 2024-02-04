#!/usr/bin/env bash

# Documentation: https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-service

set -e

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
    echo "[!] No Google Cloud project is set."
    exit 1
fi

REGISTRY_LOCATION="europe-west1"
REGISTRY_REPOSITORY="cloudbuild"

BUILD_MACHINE="e2-highcpu-8"

IMAGE=$REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$REGISTRY_REPOSITORY/wikipedia-search:latest

MODEL_IDS=${MODEL_IDS:-'intfloat/multilingual-e5-small,intfloat/multilingual-e5-base,intfloat/multilingual-e5-large,sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2'}

env_vars=(ELASTICSEARCH_URL ELASTICSEARCH_USER ELASTICSEARCH_PASSWORD)
env_vars_string=""

for var in "${env_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "[!] Variable $var is not set"; exit 1
  else
    env_vars_string="${env_vars_string}${var}=${!var},"
  fi
done

env_vars_string="${env_vars_string}"

trap 'rm -f cloudbuild.yaml' EXIT
cat <<EOF > cloudbuild.yaml
steps:
  - name: 'gcr.io/kaniko-project/executor:latest'
    args:
      - '--destination=$IMAGE'
      - '--cache=true'
      - '--compressed-caching=false'
      - '--cache-copy-layers=true'
      - '--build-arg=MODEL_IDS=$MODEL_IDS'

  - name: 'gcr.io/cloud-builders/gcloud'
    args:
    - 'run'
    - 'deploy'
    - 'wikipedia-search'
    - '--image=$IMAGE'
    - '--description="Semantic search for Wikipedia"'
    - '--set-env-vars=$env_vars_string'
    - '--memory=16G'
    - '--cpu=4'
    - '--max-instances=10'
    - '--timeout=10m'
    - '--execution-environment=gen1'
    - '--region=$REGISTRY_LOCATION'
    - '--allow-unauthenticated'
EOF

# NOTE: See <https://github.com/GoogleContainerTools/kaniko/issues/1669#issuecomment-1487953071> for preventing build failing with error 137 due to insufficient memory for Kaniko cache.

gcloud builds submit --config=cloudbuild.yaml --machine-type=$BUILD_MACHINE --disk-size=100
