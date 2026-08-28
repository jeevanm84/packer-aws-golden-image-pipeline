packer {
  required_version = ">= 1.16.0"

  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1.1"
    }
  }
}

variable "image_name" {
  type        = string
  description = "Name applied to the locally built Docker image."
  default     = "packer-learning-web"
}

source "docker" "ubuntu" {
  image  = "ubuntu:24.04"
  commit = true
}

build {
  name    = "beginner-docker"
  sources = ["source.docker.ubuntu"]

  provisioner "shell" {
    script = "${path.root}/scripts/provision.sh"
  }

  post-processor "docker-tag" {
    repository = var.image_name
    tags       = ["latest"]
  }
}
