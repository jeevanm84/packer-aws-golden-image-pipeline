#!/usr/bin/env bash
set -euo pipefail

: "${AMI_ID:?Set AMI_ID to the image produced by Packer}"
: "${AWS_REGION:?Set AWS_REGION}"
: "${SUBNET_ID:?Set SUBNET_ID to a public subnet with auto-assigned public IPv4 support}"
: "${VPC_ID:?Set VPC_ID containing SUBNET_ID}"

AWS_PROFILE_ARGS=()
if [[ -n "${AWS_PROFILE:-}" ]]; then
  AWS_PROFILE_ARGS=(--profile "$AWS_PROFILE")
fi

security_group_id=""
instance_id=""

cleanup() {
  exit_code=$?

  if [[ -n "$instance_id" ]]; then
    aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 terminate-instances \
      --instance-ids "$instance_id" >/dev/null || true
    aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 wait instance-terminated \
      --instance-ids "$instance_id" || true
  fi

  if [[ -n "$security_group_id" ]]; then
    aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 delete-security-group \
      --group-id "$security_group_id" || true
  fi

  exit "$exit_code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 describe-images \
  --image-ids "$AMI_ID" \
  --query 'Images[0].[State,Architecture,RootDeviceType]' \
  --output table

image_state="$(aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 describe-images \
  --image-ids "$AMI_ID" --query 'Images[0].State' --output text)"

if [[ "$image_state" != "available" ]]; then
  printf 'AMI %s is not available; current state: %s\n' "$AMI_ID" "$image_state" >&2
  exit 1
fi

runner_ip="$(curl --fail --silent https://checkip.amazonaws.com | tr -d '[:space:]')"
security_group_name="packer-verify-$(date +%s)"

security_group_id="$(aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 create-security-group \
  --group-name "$security_group_name" \
  --description 'Temporary HTTP access for Packer AMI verification' \
  --vpc-id "$VPC_ID" \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Project,Value=packer-aws-golden-image-pipeline},{Key=ManagedBy,Value=verification-script}]' \
  --query 'GroupId' --output text)"

aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --ip-permissions "IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=${runner_ip}/32,Description='Temporary Packer verification'}]"

instance_id="$(aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "${TEST_INSTANCE_TYPE:-t3.micro}" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$security_group_id" \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=packer-ami-verification},{Key=Project,Value=packer-aws-golden-image-pipeline},{Key=ManagedBy,Value=verification-script}]' \
  --query 'Instances[0].InstanceId' --output text)"

aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 wait instance-status-ok \
  --instance-ids "$instance_id"

public_ip="$(aws "${AWS_PROFILE_ARGS[@]}" --region "$AWS_REGION" ec2 describe-instances \
  --instance-ids "$instance_id" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"

for attempt in {1..20}; do
  if curl --fail --silent --max-time 5 "http://${public_ip}/" | grep --quiet 'Packer golden image is running'; then
    printf 'AMI smoke test passed: http://%s/\n' "$public_ip"
    exit 0
  fi
  printf 'Waiting for nginx (%s/20)...\n' "$attempt"
  sleep 10
done

printf 'AMI smoke test failed for %s.\n' "$AMI_ID" >&2
exit 1
