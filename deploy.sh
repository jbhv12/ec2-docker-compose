#!/usr/bin/env bash
# Deploy EC2 Docker Compose - auto-detects deployer IP by default, runs terraform apply
# Override: set allowed_cidr in terraform.tfvars, or ALLOWED_CIDR env var, or pass -var="allowed_cidr=X.X.X.X/32"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build -var for allowed_cidr if not already set in terraform.tfvars
EXTRA_VARS=()
if ! grep -q 'allowed_cidr' terraform.tfvars 2>/dev/null; then
  ALLOWED_CIDR="${ALLOWED_CIDR:-$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)/32}"
  if [ -z "$ALLOWED_CIDR" ] || [ "$ALLOWED_CIDR" = "/32" ]; then
    echo "Error: Could not detect your public IP. Set ALLOWED_CIDR env var or create terraform.tfvars with allowed_cidr." >&2
    exit 1
  fi
  EXTRA_VARS=(-var="allowed_cidr=$ALLOWED_CIDR")
fi

terraform init
terraform apply "${EXTRA_VARS[@]}" "$@"
