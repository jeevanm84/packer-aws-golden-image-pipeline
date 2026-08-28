# Architecture

## Local learning path

```mermaid
flowchart LR
    H[HCL template] --> P[Packer]
    P --> D[Temporary Ubuntu container]
    D --> S[Shell provisioner]
    S --> I[Tagged Docker image]
    I --> T[Local verification script]
```

## AWS pipeline

```mermaid
flowchart TD
    PR[Pull request] --> V[Format and validate]
    V --> M[Manual workflow dispatch]
    M --> E[Protected aws-build environment]
    E --> O[GitHub OIDC token]
    O --> R[AWS IAM role with temporary credentials]
    R --> P[Packer amazon-ebs]
    P --> B[Temporary EC2 build instance]
    B --> C[Provision and validate]
    C --> A[Encrypted AMI and snapshot]
    A --> J[Manifest with AMI ID]
    J --> X[Temporary verification instance]
    X --> H[HTTP smoke test]
    H --> T[Terraform consumer]
    T --> D[Guarded cleanup]
```

## Security boundaries

- Pull requests can validate code but cannot request AWS credentials.
- AWS access requires `id-token: write`, repository-scoped IAM trust, and the protected `aws-build` environment.
- No long-lived AWS key is stored in GitHub.
- The build AMI and root snapshot are encrypted.
- The build requires IMDSv2 on temporary and resulting instances.
- The cleanup script checks the exact AMI format and project tag before deregistration.
- Workflow-dispatched builds avoid accidental cloud cost on every commit.

## Deliberate learning trade-offs

- The Packer build uses temporary SSH so learners can see the standard communicator flow.
- The learning IAM policy is broad across EC2 because several creation-time operations cannot be scoped to known resource ARNs in advance.
- The HTTP smoke test uses a public test subnet and a `/32` ingress rule that exists only for the test duration.

The advanced path asks learners to replace these teaching choices with Session Manager, permission boundaries, dedicated build subnets, private networking, and organizational controls.
