# IAM and GitHub OIDC setup

This repository does not use long-lived AWS access keys in GitHub secrets. GitHub Actions requests a short-lived token through OpenID Connect and assumes an AWS IAM role scoped to this repository's protected `aws-build` environment.

## 1. Add GitHub as an IAM identity provider

In AWS IAM, add an OpenID Connect provider:

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

Only one provider is needed per AWS account.

## 2. Create the role

1. Replace `<AWS_ACCOUNT_ID>` in `github-oidc-trust-policy.template.json`.
2. Create a role named `GitHubActionsPackerBuild` using that trust policy.
3. Attach `packer-permissions-policy.json`.
4. Review the permissions with your AWS administrator before using the role outside a learning account.

The trust policy permits only workflows from `jeevanm84/packer-aws-golden-image-pipeline` using the `aws-build` GitHub environment.

## 3. Configure the GitHub environment

Create an environment named `aws-build`. Add protection rules so AMI creation and deletion require approval.

Add these environment variables:

| Variable | Example |
|---|---|
| `AWS_ACCOUNT_ID` | `123456789012` |
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsPackerBuild` |
| `AWS_REGION` | `ap-south-1` |
| `AWS_TEST_VPC_ID` | `vpc-0123456789abcdef0` |
| `AWS_TEST_SUBNET_ID` | `subnet-0123456789abcdef0` |

The test subnet must provide outbound internet access and public IPv4 assignment for the automated HTTP smoke test.

## Important boundary

The included permission policy is deliberately understandable for a learning account and uses `Resource: "*"` because several EC2 image-building actions do not support narrow resource scoping during creation. It is not a universal production policy. Add service-control policies, permission boundaries, dedicated accounts, monitoring, and tighter conditions in a real organization.
