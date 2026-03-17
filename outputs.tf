output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2_docker_compose.public_ip
}

output "ssh_username" {
  description = "SSH username for connecting to the instance"
  value       = module.ec2_docker_compose.ssh_username
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2_docker_compose.instance_id
}

output "ssh_password" {
  description = "Random password for SSH (ec2-user)"
  value       = module.ec2_docker_compose.ssh_password
  sensitive   = true
}
