variable "aws_region" {
  type        = string
  description = "AWS region in which Packer builds the AMI."
  default     = "ap-south-1"
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix for the generated AMI name."
  default     = "packer-learning"

  validation {
    condition     = length(var.ami_name_prefix) >= 3 && length(var.ami_name_prefix) <= 40
    error_message = "The AMI name prefix must contain between 3 and 40 characters."
  }
}

variable "instance_type" {
  type        = string
  description = "Temporary EC2 instance type used during the image build."
  default     = "t3.micro"
}

variable "source_ami_name" {
  type        = string
  description = "Canonical Ubuntu AMI name filter."
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed to reach temporary SSH. Prefer a narrow runner/NAT CIDR."
  default     = "203.0.113.10/32"
}

variable "build_commit" {
  type        = string
  description = "Git commit associated with the image build."
  default     = "local"
}
