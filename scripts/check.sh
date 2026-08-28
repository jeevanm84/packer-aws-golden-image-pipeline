#!/usr/bin/env bash
set -euo pipefail

required=(packer terraform docker jq)
missing=()

for command_name in "${required[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

if ((${#missing[@]} > 0)); then
  printf 'Missing required commands: %s\n' "${missing[*]}" >&2
  exit 1
fi

packer fmt -check -recursive beginner
packer fmt -check -recursive aws
packer init beginner/docker
packer validate beginner/docker
packer init aws
packer validate -var-file=aws/environments/learning.pkrvars.example.hcl aws

terraform -chdir=terraform/example-instance init -backend=false
terraform -chdir=terraform/example-instance fmt -check -recursive
terraform -chdir=terraform/example-instance validate

for script in beginner/docker/scripts/*.sh aws/scripts/*.sh scripts/*.sh; do
  bash -n "$script"
done

printf 'All non-cloud checks passed.\n'
