#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Terraform apply for NSE sandbox (launch-system: api, orchestrator, executors, public data EFS)"

terraform -chdir="${REPO_ROOT}" apply -auto-approve \
    -target=module.launch_system \
    -target=module.bastion_host \
    -target=module.public_data_efs_storage \
    -var-file="${REPO_ROOT}/sandbox-nse.tfvars"
