# Contributing

Contributions that make the learning path safer, clearer, or more reproducible are welcome.

## Before changing code

- Search existing issues.
- Open a design issue before adding a cloud, credential, or deployment path.
- Never commit credentials, account IDs, private network identifiers, state files, or customer data.
- Keep one pull request focused on one learning outcome.

## Validate locally

```bash
make check
```

Cloud changes must also document:

- resources created;
- approximate lifecycle and cost exposure;
- permissions required;
- success checkpoint;
- idempotent or guarded cleanup;
- failure recovery.

## Pull request expectations

- Explain the problem and audience level.
- Update the end-to-end guide when the ordered workflow changes.
- Include command output or workflow links demonstrating validation.
- Never weaken deletion guards or OIDC trust for convenience.
- Add screenshots only when they clarify an AWS or GitHub UI step.

By contributing, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
