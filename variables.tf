# Required: Your public IP for security group. Get with: curl -s ifconfig.me
variable "allowed_cidr" {
  description = "CIDR block for inbound access (e.g., deployer IP/32). Get your IP: curl -s ifconfig.me"
  type        = string
}

# Path to your Docker Compose file. Replace docker-compose.yml with your own.
variable "compose_file_path" {
  description = "Path to Docker Compose file (relative to repo root)"
  type        = string
  default     = "docker-compose.yml"
}

# AWS region. us-east-1 is default; change for other regions.
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

# Instance type. t3.micro minimizes cost (~$0.01/hr); use t3.small for more RAM.
variable "instance_type" {
  description = "EC2 instance type (default minimizes cost)"
  type        = string
  default     = "t3.micro"
}

# Root disk size in GB. Amazon Linux 2023 requires min 30 GB.
variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB (gp3); min 30 for AL2023"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size_gb >= 30
    error_message = "root_volume_size_gb must be >= 30 for Amazon Linux 2023."
  }
}
