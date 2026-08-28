variable "aws_region" {
  type        = string
  description = "AWS region containing the Packer AMI."
  default     = "ap-south-1"
}

variable "ami_id" {
  type        = string
  description = "AMI ID emitted by the Packer manifest."

  validation {
    condition     = can(regex("^ami-[a-f0-9]+$", var.ami_id))
    error_message = "ami_id must be a valid AWS AMI ID."
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet in which to launch the demonstration instance."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Existing security groups for the demonstration instance."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the demonstration consumer."
  default     = "t3.micro"
}
