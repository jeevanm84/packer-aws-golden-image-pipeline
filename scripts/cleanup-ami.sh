#!/usr/bin/env bash
set -euo pipefail

: "${AMI_ID:?Set the exact AMI_ID to remove}"
: "${AWS_REGION:?Set AWS_REGION}"

if [[ ! "$AMI_ID" =~ ^ami-[a-f0-9]+$ ]]; then
  printf 'Refusing invalid AMI ID: %s\n' "$AMI_ID" >&2
  exit 1
fi

AWS_PROFILE_ARGS=()
if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS_PROFILE_ARGS=(--profile "$AWS_PROFILE")
fi

project_tag="$(aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 describe-images \
  --owners self --image-ids "$AMI_ID" \
  --query "Images[0].Tags[?Key=='Project'].Value | [0]" --output text)"

if [[ "$project_tag" != "packer-aws-golden-image-pipeline" ]]; then
  printf 'Refusing to delete %s: expected project tag was not found.\n' "$AMI_ID" >&2
  exit 1
fi

snapshot_ids="$(aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 describe-images \
  --owners self --image-ids "$AMI_ID" \
  --query 'Images[0].BlockDeviceMappings[].Ebs.SnapshotId' --output text)"

printf 'Deregistering %s...\n' "$AMI_ID"
aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 deregister-image --image-id "$AMI_ID"

for snapshot_id in $snapshot_ids; do
  if [[ "$snapshot_id" =~ ^snap-[a-f0-9]+$ ]]; then
    printf 'Deleting %s...\n' "$snapshot_id"
    aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 delete-snapshot --snapshot-id "$snapshot_id"
  fi
done

printf 'Cleanup complete for %s.\n' "$AMI_ID"
