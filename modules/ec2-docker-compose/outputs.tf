output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.ec2_docker.public_ip
}

output "ssh_username" {
  description = "SSH username for connecting to the instance"
  value       = "ec2-user"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ec2_docker.id
}

output "ssh_password" {
  description = "Random password for SSH (ec2-user)"
  value       = random_password.ssh_password.result
  sensitive   = true
}
