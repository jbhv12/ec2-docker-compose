# Required: CIDR for inbound access. Use your IP/32 (e.g., 1.2.3.4/32).
variable "allowed_cidr" {
  description = "CIDR block for inbound access (e.g., deployer IP/32)"
  type        = string
}

# AWS region. Affects where EC2 and security group are created.
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

# Instance type. t3.micro = lowest cost; t3.small = more RAM.
variable "instance_type" {
  description = "EC2 instance type (default minimizes cost)"
  type        = string
  default     = "t3.micro"
}

# Root EBS volume size. gp3 is used. Amazon Linux 2023 requires min 30 GB.
variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB (gp3); min 30 for AL2023"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size_gb >= 30
    error_message = "root_volume_size_gb must be >= 30 for Amazon Linux 2023."
  }
}

# Path to compose file relative to root. Used when compose_file_content not set.
variable "compose_file_path" {
  description = "Path to Docker Compose file (relative to root)"
  type        = string
  default     = "docker-compose.yml"
}

# Raw compose content. Overrides compose_file_path when set (for module reuse).
variable "compose_file_content" {
  description = "Raw compose file content (passed from root, overrides path if set)"
  type        = string
  default     = ""
}
