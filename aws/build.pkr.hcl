build {
  name    = "aws-ubuntu-golden-image"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    environment_vars = [
      "BUILD_COMMIT=${var.build_commit}",
    ]
    script = "${path.root}/scripts/provision.sh"
  }

  provisioner "shell" {
    script = "${path.root}/scripts/validate.sh"
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
    custom_data = {
      build_commit    = var.build_commit
      source_ami_id   = build.SourceAMI
      source_ami_name = build.SourceAMIName
    }
  }
}
