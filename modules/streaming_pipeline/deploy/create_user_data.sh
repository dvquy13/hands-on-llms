#!/bin/bash

# Source the environment variables if .env file exists
if [ -f ".env" ]; then
    source .env
else
    echo ".env file does not exist."
fi

# Query the ECR registry URI.
DOCKER_IMAGE_ECR_REGISTRY_URI=$(aws ecr describe-repositories --repository-names ${AWS_ECR_REPO_NAME} --query "repositories[?repositoryName==\`${AWS_ECR_REPO_NAME}\`].repositoryUri" --output text --region $AWS_REGION 2>/dev/null)

if [ -z "$DOCKER_IMAGE_ECR_REGISTRY_URI" ]; then
    echo "Repository ${AWS_ECR_REPO_NAME} does not exist, creating..."
    aws ecr create-repository --repository-name ${AWS_ECR_REPO_NAME} --region $AWS_REGION
    DOCKER_IMAGE_ECR_REGISTRY_URI=$(aws ecr describe-repositories --repository-names ${AWS_ECR_REPO_NAME} --query "repositories[?repositoryName==\`${AWS_ECR_REPO_NAME}\`].repositoryUri" --output text --region $AWS_REGION)
fi

export DOCKER_IMAGE_ECR_REGISTRY_URI

if [ -z "$DOCKER_IMAGE_ECR_REGISTRY_URI" ]; then
    echo "DOCKER_IMAGE_ECR_REGISTRY_URI is not set. Most probably because the AWS_ECR_REPO_NAME=${AWS_ECR_REPO_NAME} ECR repository does not exist. Exiting script."
    exit 1
fi

echo "DOCKER_IMAGE_ECR_REGISTRY_URI=${DOCKER_IMAGE_ECR_REGISTRY_URI}"

# TODO: Refactor because these Build and Push steps logically should not occur here because this script only focuses on user-data.
# Build docker image
LOCAL_IMAGE_TAG="streaming_pipeline:latest"
docker build -t $LOCAL_IMAGE_TAG -f deploy/Dockerfile .


ECR_LOGIN_PASSWORD=$(aws ecr get-login-password --region ${AWS_REGION} 2>/dev/null)
if [ -z "$ECR_LOGIN_PASSWORD" ]; then
    echo "Failed to get ECR Login Password. Aborting."
    exit 1
fi

export ECR_LOGIN_PASSWORD

# ECR login
docker login --username AWS --password ${ECR_LOGIN_PASSWORD} ${DOCKER_IMAGE_ECR_REGISTRY_URI}

# Push docker image to ECR
ECR_IMAGE_TAG="${DOCKER_IMAGE_ECR_REGISTRY_URI}:latest"
echo "Pushing image: ${ECR_IMAGE_TAG}"
docker tag $LOCAL_IMAGE_TAG $ECR_IMAGE_TAG
docker push $ECR_IMAGE_TAG


# Extract all variables from the template
# Below command works with GNU grep
# variables=$(grep -oP '\$\{\K[^}]*' deploy/user_data_template.sh)
# Below command works with BSD grep (MacOS)
variables=$(grep -o '\${[^}]*' deploy/user_data_template.sh | sed 's/^\${//' | sed 's/}$//')


# Define your list of strings
allowed_variables=("DOCKER_IMAGE_ECR_REGISTRY_URI")

# Flag to indicate if all variables are set
all_set=true

# Iterate through all variables and check if they are set
for var in $variables; do
  if [[ -z "${!var}" ]]; then
    echo "Environment variable $var is not set."
    all_set=false
  fi
done

# Only run envsubst if all variables are set
# If on MacOS, run `brew install gettext`
if $all_set; then
  envsubst < deploy/user_data_template.sh > deploy/user_data.sh

  exit 0
else
  echo "Not all variables are set in your '.env' file. Aborting."

  exit 1
fi
