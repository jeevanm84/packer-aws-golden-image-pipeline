# Complete end-to-end guide

Follow this guide in order. Each phase ends with a checkpoint. Do not continue to an AWS phase until the previous checkpoint passes.

## What completion means

By the end, you will be able to prove that:

- Packer templates are formatted and valid;
- a free local image can be built and tested;
- GitHub Actions validates every pull request;
- GitHub obtains temporary AWS credentials through OIDC;
- Packer produces an encrypted AWS AMI with IMDSv2 required;
- the AMI ID is recorded in a manifest;
- a new EC2 instance boots from the AMI and serves the expected page;
- Terraform can consume the AMI;
- the AMI, snapshots, and test infrastructure are removed safely.

## Phase 0: understand cost and safety

The beginner Docker lab is local. AWS phases can create EC2 instances, EBS volumes and snapshots, and AMIs. Charges can apply even after the build finishes because snapshots remain until deleted.

Before AWS work:

1. use a dedicated learning account if possible;
2. configure an AWS Budget and billing alert;
3. choose one region and keep all commands in that region;
4. never use root credentials;
5. plan to run Phase 8 cleanup during the same session.

## Phase 1: install the tools

Required for every track:

- Git;
- HashiCorp Packer 1.16.0 or newer;
- Docker;
- Bash;
- `jq`.

Also required for AWS and advanced tracks:

- AWS CLI v2;
- Terraform 1.6 or newer;
- a GitHub account;
- access to a sandbox AWS account.

Verify:

```bash
git --version
packer version
docker version
jq --version
aws --version
terraform version
```

Clone the repository:

```bash
git clone https://github.com/jeevanm84/packer-aws-golden-image-pipeline.git
cd packer-aws-golden-image-pipeline
```

Checkpoint:

```bash
make help
```

You should see the supported lab commands.

## Phase 2: beginner Docker image lab

This phase teaches the Packer lifecycle without cloud credentials or AWS charges.

### 2.1 Read the template

Open `beginner/docker/docker-ubuntu.pkr.hcl`. Identify:

- `required_plugins`: downloads the official Docker builder;
- `variable`: lets callers change the resulting image name;
- `source`: chooses Ubuntu 24.04 as the build input;
- `build`: attaches provisioning and tagging to the source;
- `provisioner`: installs nginx and creates a test page;
- `post-processor`: tags the committed Docker image.

### 2.2 Initialize and validate

```bash
packer fmt -check -recursive beginner/docker
packer init beginner/docker
packer inspect beginner/docker
packer validate beginner/docker
```

Checkpoint: `packer validate` ends with `The configuration is valid.`

### 2.3 Build and test

```bash
packer build beginner/docker
docker image inspect packer-learning-web:latest
./scripts/test-docker-image.sh
```

Checkpoint:

```text
Docker image verification passed for packer-learning-web:latest.
```

### 2.4 Clean local output

```bash
docker image rm packer-learning-web:latest
```

You now understand Packer before introducing AWS complexity.

## Phase 3: validate the AWS template without building

Read the files under `aws/` in this order:

1. `versions.pkr.hcl` pins the Amazon plugin;
2. `variables.pkr.hcl` defines user-controlled inputs;
3. `sources.pkr.hcl` selects Canonical Ubuntu and configures `amazon-ebs`;
4. `build.pkr.hcl` provisions, validates, and writes a manifest;
5. `scripts/provision.sh` installs and configures nginx;
6. `scripts/validate.sh` proves the image contents are correct before capture.

Initialize and validate without AWS credentials:

```bash
packer fmt -check -recursive aws
packer init aws
packer validate \
  -var-file=aws/environments/learning.pkrvars.example.hcl \
  aws
```

Checkpoint: the configuration is valid and no EC2 resources were created.

## Phase 4: authenticate locally to AWS

AWS IAM Identity Center / SSO is preferred for a human operator because it provides temporary credentials.

Configure a profile if your account provides SSO:

```bash
aws configure sso
aws sso login --profile your-aws-sso-profile
export AWS_PROFILE=your-aws-sso-profile
export AWS_REGION=ap-south-1
```

Verify the identity and region:

```bash
aws sts get-caller-identity
aws configure get region --profile "$AWS_PROFILE"
```

Checkpoint: the returned account ID is the intended sandbox account. Stop immediately if it is a production or corporate account you did not intend to use.

## Phase 5: build a real AWS AMI locally

### 5.1 Choose a narrow SSH source

Packer temporarily connects over SSH. Find your current public IPv4 address:

```bash
curl --silent https://checkip.amazonaws.com
```

Copy the example values:

```bash
cp aws/environments/learning.pkrvars.example.hcl aws/environments/learning.pkrvars.hcl
```

Edit the new ignored file and replace the documentation-only address with your public address followed by `/32`:

```hcl
allowed_ssh_cidr = "203.0.113.10/32"
```

### 5.2 Build

```bash
packer build \
  -on-error=cleanup \
  -var-file=aws/environments/learning.pkrvars.hcl \
  aws
```

Packer launches a temporary instance, runs both provisioners, creates the AMI, terminates its build resources, and writes `packer-manifest.json`.

Checkpoint:

```bash
export AMI_ID="$(./scripts/get-ami-id.sh packer-manifest.json)"
echo "$AMI_ID"
aws ec2 describe-images \
  --region "$AWS_REGION" \
  --owners self \
  --image-ids "$AMI_ID" \
  --query 'Images[0].[ImageId,Name,State,CreationDate]' \
  --output table
```

The image state must be `available`.

## Phase 6: prove the AMI boots and serves traffic

Find a test VPC and a public subnet. The subnet must route outbound traffic through an internet gateway and support a public IPv4 address.

```bash
export VPC_ID=vpc-replace-me
export SUBNET_ID=subnet-replace-me
```

Run the smoke test:

```bash
./scripts/verify-ami.sh
```

The script:

1. verifies the AMI is available;
2. creates a temporary security group allowing port 80 only from your current public IP;
3. launches a temporary instance from the AMI;
4. waits for EC2 status checks;
5. requests the nginx page and checks its content;
6. terminates the instance and deletes the security group through a cleanup trap.

Checkpoint:

```text
AMI smoke test passed
```

Confirm no verification instance remains:

```bash
aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters 'Name=tag:ManagedBy,Values=verification-script' \
  --query 'Reservations[].Instances[?State.Name!=`terminated`].[InstanceId,State.Name]' \
  --output table
```

## Phase 7: build securely through GitHub Actions

The repository intentionally does not store AWS access keys in GitHub secrets.

### 7.1 Create GitHub OIDC trust

Follow [the IAM guide](../iam/README.md):

1. register GitHub's OIDC provider in the sandbox AWS account;
2. replace `<AWS_ACCOUNT_ID>` in the trust-policy template;
3. create the `GitHubActionsPackerBuild` role;
4. attach the learning permission policy;
5. create a protected GitHub environment named `aws-build`;
6. add the documented environment variables;
7. require approval for the environment.

### 7.2 Validate through a pull request

```bash
git switch -c docs/first-learning-change
git commit --allow-empty -m "test: verify Packer validation workflow"
git push -u origin docs/first-learning-change
```

Open a pull request and confirm the `Validate` workflow passes. This workflow formats and validates Packer and Terraform but creates no AWS resources.

### 7.3 Build manually

1. Open **Actions → Build and verify AMI**.
2. Select **Run workflow**.
3. Keep **run smoke test** enabled.
4. Approve the `aws-build` environment when prompted.
5. Confirm the AWS identity step uses the sandbox account.
6. Watch Packer build and the verification test.
7. Download the 30-day manifest artifact.

Checkpoint: the workflow summary shows an AMI ID and the smoke-test step passes.

## Phase 8: consume the AMI with Terraform

This is an optional learning step that creates another EC2 instance.

```bash
cd terraform/example-instance
cp terraform.tfvars.example terraform.tfvars
```

Replace the AMI, subnet, and security-group placeholders. Then:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Checkpoint:

```bash
terraform output
```

Destroy the consumer before continuing:

```bash
terraform destroy
cd ../..
```

## Phase 9: deregister the AMI and delete snapshots

The cleanup script refuses to remove an image unless its `Project` tag exactly matches this repository.

Review the target:

```bash
aws ec2 describe-images \
  --region "$AWS_REGION" \
  --owners self \
  --image-ids "$AMI_ID" \
  --output table
```

Delete it:

```bash
./scripts/cleanup-ami.sh
```

Alternatively, use **Actions → Cleanup AMI**, enter the exact AMI ID, type `DELETE`, and approve the protected environment.

Checkpoint:

```bash
aws ec2 describe-images \
  --region "$AWS_REGION" \
  --owners self \
  --image-ids "$AMI_ID"
```

The AMI should no longer be returned. Also inspect EC2 instances, EBS snapshots, security groups, and the AWS billing dashboard before ending the session.

## Phase 10: advanced exercises

Complete these one at a time through design issues and pull requests:

- replace public SSH with AWS Systems Manager Session Manager;
- use a customer-managed KMS key for AMI and snapshot encryption;
- add vulnerability and CIS benchmark scanning;
- schedule rebuilds when Canonical publishes a newer base AMI;
- copy images to a second region;
- share images from a tooling account to workload accounts;
- add semantic image channels through HCP Packer;
- emit and verify Packer 1.16 provenance attestations;
- implement retention that keeps the latest approved images and removes older ones;
- promote an AMI through development, staging, and production without rebuilding it.

## Final checklist

- [ ] Beginner Docker image builds and passes its test.
- [ ] AWS Packer files validate.
- [ ] The local AWS identity is a sandbox identity.
- [ ] The AMI is encrypted, tagged, and requires IMDSv2.
- [ ] The manifest contains the AMI ID.
- [ ] A fresh EC2 instance passes the HTTP smoke test.
- [ ] GitHub Actions uses OIDC and a protected environment.
- [ ] Terraform can consume the AMI.
- [ ] Terraform consumer resources are destroyed.
- [ ] The learning AMI is deregistered.
- [ ] Associated snapshots are deleted.
- [ ] No temporary instances or security groups remain.

Completing every checked item demonstrates the full golden-image lifecycle, not merely a successful `packer build` command.
