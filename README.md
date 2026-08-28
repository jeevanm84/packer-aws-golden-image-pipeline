<div align="center">

# Packer AWS Golden Image Pipeline

### Learn image automation by building, testing, publishing, consuming, and cleaning up real artifacts

[![Validate](https://github.com/jeevanm84/packer-aws-golden-image-pipeline/actions/workflows/validate.yml/badge.svg)](https://github.com/jeevanm84/packer-aws-golden-image-pipeline/actions/workflows/validate.yml)
[![Packer](https://img.shields.io/badge/Packer-1.16.0-844FBA?logo=packer)](https://developer.hashicorp.com/packer)
[![License: MIT](https://img.shields.io/badge/License-MIT-2563eb.svg)](LICENSE)

[Start the complete guide](docs/END_TO_END_GUIDE.md) · [Architecture](docs/ARCHITECTURE.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Interview questions](docs/INTERVIEW_QUESTIONS.md)

</div>

> [!IMPORTANT]
> Start with [the complete end-to-end guide](docs/END_TO_END_GUIDE.md). It is the canonical path from installing Packer to proving an AWS AMI works and deleting every learning resource safely.

## What you will build

This repository contains three progressive learning tracks:

| Level | Outcome | Cloud cost |
|---|---|---|
| Beginner | Build and verify an Ubuntu-based Docker image with Packer | None beyond local resources |
| Intermediate | Build a tagged, encrypted, IMDSv2-enforced AWS AMI and capture its ID | AWS charges may apply |
| Advanced | Build through GitHub Actions OIDC, smoke-test the AMI, consume it with Terraform, and clean it up | AWS charges may apply |

The final workflow is:

```text
Pull request validation
  → approved GitHub environment
  → short-lived AWS credentials through OIDC
  → Packer AMI build
  → image-internal validation
  → manifest with AMI ID
  → temporary EC2 smoke test
  → Terraform consumer
  → guarded AMI and snapshot cleanup
```

## Why this repository is different

- One ordered guide for beginner, intermediate, and experienced readers.
- No long-lived AWS access keys stored in GitHub.
- Every phase has a visible success checkpoint.
- Cloud creation is manual and approval-friendly—not triggered on every push.
- Verification launches a real instance from the generated AMI.
- Cleanup refuses to delete an AMI without the expected project tag.
- Interview explanations are connected to executable code.

## Quick start: free beginner lab

Prerequisites: Packer, Docker, Git, Bash, and `jq`.

```bash
git clone https://github.com/jeevanm84/packer-aws-golden-image-pipeline.git
cd packer-aws-golden-image-pipeline
packer init beginner/docker
packer validate beginner/docker
packer build beginner/docker
./scripts/test-docker-image.sh
```

Expected final line:

```text
Docker image verification passed for packer-learning-web:latest.
```

No AWS account is required for this beginner lab. AWS workflows are manual-only and require an explicitly configured `aws-build` GitHub environment before they can access a cloud account.

## Verification boundaries

Pull requests validate Packer formatting and configuration, Terraform configuration, and shell syntax without contacting AWS. The free Docker lab exercises a complete local build and runtime test. A real AMI build is deliberately excluded from automatic CI because it creates billable AWS resources; follow the guide's identity, budget, approval, verification, and cleanup checkpoints when you later use a learning account.

## Repository map

```text
.
├── beginner/docker/       Zero-cost first image build
├── aws/                   Production-style Ubuntu AMI template
├── iam/                   GitHub OIDC trust and learning permissions
├── scripts/               Validation, smoke test, manifest, cleanup
├── terraform/             Example consumer of the generated AMI
├── .github/workflows/     Validation, AMI build, and cleanup pipelines
└── docs/                  End-to-end guide and technical reference
```

## Safety boundaries

- Use a sandbox or learning AWS account with a budget alarm.
- Review all IAM policies with your administrator.
- Run AWS builds only through manual workflow dispatch or deliberate local commands.
- Never commit AWS keys, `.pkrvars.hcl` secrets, state files, or private keys.
- Run cleanup after every practice session.
- This repository is an educational reference, not a drop-in organizational golden-image platform.

## Contributing

Issues and focused pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md), follow the [Code of Conduct](CODE_OF_CONDUCT.md), and report security concerns through [SECURITY.md](SECURITY.md).

Created and maintained by [@jeevanm84](https://github.com/jeevanm84).
