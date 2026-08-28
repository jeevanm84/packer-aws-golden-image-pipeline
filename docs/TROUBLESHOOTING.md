# Troubleshooting

## `packer` is not HashiCorp Packer

```bash
packer version
```

If the command references a password dictionary or an unrelated package manager, remove the conflicting binary and install Packer from HashiCorp.

## Docker daemon is unavailable

Start Docker Desktop, then verify:

```bash
docker info
```

## Plugin initialization fails

```bash
rm -rf ~/.config/packer/plugins
PACKER_LOG=1 packer init beginner/docker
```

Remove the plugin cache only when its contents are corrupt; otherwise keep it for faster builds.

## AWS credentials are missing or expired

```bash
aws sso login --profile "$AWS_PROFILE"
aws sts get-caller-identity
```

Never solve this by committing access keys.

## No source AMI matches

Confirm the region and Canonical image names:

```bash
aws ec2 describe-images \
  --region "$AWS_REGION" \
  --owners 099720109477 \
  --filters \
    'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' \
    'Name=architecture,Values=x86_64' \
    'Name=state,Values=available' \
  --query 'reverse(sort_by(Images,&CreationDate))[:5].[ImageId,Name,CreationDate]' \
  --output table
```

## Packer cannot connect over SSH

- Confirm `allowed_ssh_cidr` is your current public IPv4 plus `/32`.
- Confirm the temporary instance receives a public IP.
- Confirm the VPC has an internet gateway and routing.
- Corporate VPNs may change or block the source address.

Run with detailed logging only after checking that logs will not expose sensitive values:

```bash
PACKER_LOG=1 packer build -on-error=abort -var-file=aws/environments/learning.pkrvars.hcl aws
```

Use `-on-error=abort` only while debugging because it intentionally leaves the temporary build instance for inspection. Terminate it manually afterward.

## GitHub OIDC access is denied

Check:

- workflow permission includes `id-token: write`;
- provider audience is `sts.amazonaws.com`;
- trust-policy repository is exactly `jeevanm84/packer-aws-golden-image-pipeline`;
- environment is exactly `aws-build`;
- `AWS_ROLE_ARN` and `AWS_ACCOUNT_ID` refer to the same account.

## Smoke test cannot reach nginx

- Confirm the subnet assigns a public IPv4 address.
- Confirm it routes through an internet gateway.
- Confirm network ACLs allow inbound and return traffic.
- Confirm your public IP did not change during the test.
- Inspect the instance console output before the cleanup trap terminates it by temporarily running the underlying AWS commands manually.

## Cleanup refuses the AMI

This is intentional when the project tag is missing. Inspect the image:

```bash
aws ec2 describe-images --region "$AWS_REGION" --owners self --image-ids "$AMI_ID"
```

Do not weaken the guard simply to make deletion easier. Confirm ownership and delete carefully through AWS if the image is genuinely yours but predates the project tag.

## Cost continues after the build

Check all of these in the chosen region:

```bash
aws ec2 describe-instances --region "$AWS_REGION" --filters 'Name=instance-state-name,Values=pending,running,stopping,stopped'
aws ec2 describe-images --region "$AWS_REGION" --owners self
aws ec2 describe-snapshots --region "$AWS_REGION" --owner-ids self
aws ec2 describe-volumes --region "$AWS_REGION" --filters 'Name=status,Values=available'
```

An AMI itself references one or more EBS snapshots; deregistering the AMI does not automatically delete those snapshots.
