#!/usr/bin/env bash
set -euo pipefail

MANIFEST_FILE="${1:-packer-manifest.json}"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  printf 'Manifest not found: %s\n' "$MANIFEST_FILE" >&2
  exit 1
fi

ami_id="$(jq -er '.builds[-1].artifact_id | split(":")[-1] | select(test("^ami-[a-f0-9]+$"))' "$MANIFEST_FILE")"
printf '%s\n' "$ami_id"
