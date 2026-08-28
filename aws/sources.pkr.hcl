source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_name_prefix}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  ssh_username  = "ubuntu"

  source_ami_filter {
    filters = {
      name                = var.source_ami_name
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }

    most_recent = true
    owners      = ["099720109477"]
  }

  associate_public_ip_address               = true
  temporary_security_group_source_public_ip = false
  temporary_security_group_source_cidrs     = [var.allowed_ssh_cidr]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  encrypt_boot = true

  tags = {
    Name        = "${var.ami_name_prefix}-golden-image"
    Project     = "packer-aws-golden-image-pipeline"
    ManagedBy   = "Packer"
    GitCommit   = var.build_commit
    Environment = "learning"
  }

  run_tags = {
    Name      = "packer-temporary-build"
    Project   = "packer-aws-golden-image-pipeline"
    ManagedBy = "Packer"
  }

  snapshot_tags = {
    Project   = "packer-aws-golden-image-pipeline"
    ManagedBy = "Packer"
    GitCommit = var.build_commit
  }
}
