.DEFAULT_GOAL := help

.PHONY: help fmt init validate beginner-build beginner-test aws-build aws-manifest terraform-check check

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Packer golden-image lab commands:\n\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

fmt: ## Format every Packer and Terraform file
	packer fmt -recursive beginner
	packer fmt -recursive aws
	terraform -chdir=terraform/example-instance fmt -recursive

init: ## Install Packer plugins
	packer init beginner/docker
	packer init aws

validate: init ## Validate both Packer learning tracks
	packer validate beginner/docker
	packer validate -var-file=aws/environments/learning.pkrvars.example.hcl aws

beginner-build: ## Build the zero-cost Docker image
	packer build beginner/docker

beginner-test: ## Verify the beginner image locally
	./scripts/test-docker-image.sh

aws-build: ## Build an AWS AMI using the example variable file
	packer build -var-file=aws/environments/learning.pkrvars.example.hcl aws

aws-manifest: ## Print the AMI ID from the latest manifest
	./scripts/get-ami-id.sh packer-manifest.json

terraform-check: ## Format and validate the Terraform consumer
	terraform -chdir=terraform/example-instance init -backend=false
	terraform -chdir=terraform/example-instance fmt -check -recursive
	terraform -chdir=terraform/example-instance validate

check: ## Run all checks that do not create cloud resources
	./scripts/check.sh
