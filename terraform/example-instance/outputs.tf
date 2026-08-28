output "instance_id" {
  description = "ID of the instance launched from the Packer AMI."
  value       = aws_instance.golden_image_demo.id
}

output "private_ip" {
  description = "Private IPv4 address of the demonstration instance."
  value       = aws_instance.golden_image_demo.private_ip
}
