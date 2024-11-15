#!/usr/bin/env bash

set -ex

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -qy install podman skopeo curl jq awscli

export ECR_URL=$(curl -H "PRIVATE-TOKEN:${GITLAB_API_READ_TOKEN}" https://bbpgitlab.epfl.ch/api/v4/projects/2295/terraform/state/default |  jq -r .outputs.resource_provisioner_ecr_url.value)

# aws ecr get-login-password reads credentials either from ~/.aws/credentials or from AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin ${ECR_URL}
aws ecr get-login-password --region us-east-1 | skopeo login --username AWS --password-stdin ${ECR_URL}

# try to check the ECR repo to make sure we actually need to pull first
DOCKERHUB_CONTAINER_INFO=$(skopeo inspect docker://bluebrain/hpc-resource-provisioner:latest)
DOCKERHUB_CHECKSUM=$(echo ${DOCKERHUB_CONTAINER_INFO} | jq -r '.Labels."org.opencontainers.image.checksum"')
set +e  # this can fail, but it's okay, that just means the image is not present
ECR_CHECKSUM=$(skopeo inspect docker://${ECR_URL}:latest | jq -r '.Labels."org.opencontainers.image.checksum"')
set -e

echo "DOCKERHUB_CONTAINER_INFO is ${DOCKERHUB_CONTAINER_INFO}"

if [[ "${DOCKERHUB_CHECKSUM}" == "${ECR_CHECKSUM}" ]];
then
    echo "Image already present in ECR - no need to re-upload"
    exit 0
else
    echo "Image not present: ${DOCKERHUB_CHECKSUM} != ${ECR_CHECKSUM}"
    CONTAINER_SOFTWARE_VERSION=$(echo ${DOCKERHUB_CONTAINER_INFO} | jq -r '.Labels."org.opencontainers.image.software_version"')
    echo "CONTAINER_SOFTWARE_VERSION is ${CONTAINER_SOFTWARE_VERSION}"
    podman pull docker.io/bluebrain/hpc-resource-provisioner:latest
    podman push bluebrain/hpc-resource-provisioner:latest ${ECR_URL}:latest
    podman push bluebrain/hpc-resource-provisioner:latest ${ECR_URL}:${CONTAINER_SOFTWARE_VERSION}
fi
