# Interview questions connected to the implementation

## Beginner

### What problem does Packer solve?

Packer turns machine-image construction into version-controlled code. Instead of repeatedly configuring every server after launch, a team can bake a reviewed configuration into a reusable image and launch consistent instances from it.

### What are source and build blocks?

A source describes how Packer obtains and launches the temporary build environment. A build selects one or more sources and attaches provisioners and post-processors. See `beginner/docker/docker-ubuntu.pkr.hcl` for both in one file.

### Why run `packer init`, `fmt`, and `validate` separately?

`init` installs declared plugins, `fmt` standardizes HCL, and `validate` catches configuration errors without creating an image. Separating these in CI fails quickly before cloud resources are launched.

## Intermediate

### Why use a source AMI filter rather than a hard-coded AMI ID?

AMI IDs differ between regions and publishers release updated base images. The filter in `aws/sources.pkr.hcl` constrains the owner to Canonical and selects the most recent Ubuntu 24.04 image matching the expected architecture and storage type.

### What happens during this AWS build?

Packer discovers the base AMI, creates temporary networking and key material, launches an EC2 instance, connects over SSH, runs provisioning and validation, stops the instance, creates an encrypted AMI and snapshot, and cleans temporary build resources. The manifest records the resulting AMI ID.

### Does a green Packer build prove the image works?

It proves the build steps completed, but not necessarily that a new instance boots and serves the intended workload. `scripts/verify-ami.sh` launches a fresh instance and performs an HTTP content check before cleaning up.

### Why require IMDSv2?

IMDSv2 uses session-oriented requests and reduces exposure to several metadata-service attack paths. The source config requires tokens so both the temporary build instance and resulting AMI enforce the stronger mode.

## Advanced

### Why use GitHub OIDC instead of AWS keys in secrets?

OIDC exchanges a GitHub identity token for short-lived AWS role credentials. There is no long-lived AWS secret to copy, rotate, or accidentally expose. The IAM trust policy constrains who may assume the role.

### Why is the AMI build manually dispatched?

Pull requests and main-branch commits should validate cheaply. Image creation incurs cost and changes cloud state, so the repository requires a deliberate manual dispatch and protected-environment approval.

### How does the image reach Terraform?

The manifest post-processor writes the AMI artifact ID to `packer-manifest.json`. `scripts/get-ami-id.sh` validates and extracts it, and the Terraform consumer accepts it through the `ami_id` variable.

### How would you promote images across environments?

Build once, test the immutable AMI, and promote the same artifact ID or copied regional equivalents through explicit channels. Do not rebuild separately for development, staging, and production because that creates different artifacts.

### What failure modes need production handling?

- base-image updates or revocation;
- provisioner network failures;
- orphaned temporary resources;
- vulnerable packages discovered after publication;
- snapshot sharing and encryption restrictions;
- cross-region or cross-account copy failures;
- consumers pinned to deprecated images;
- concurrent builds and image-name collisions;
- retention and rollback correctness.

### What would you add for an enterprise implementation?

Dedicated tooling accounts, private build subnets, Session Manager, KMS keys, permission boundaries, policy-as-code, vulnerability scanning, signed provenance, centralized image metadata, promotion channels, retention automation, monitoring, and tested break-glass rollback.
