# Contract: ec2-docker-compose Terraform Module

**Purpose**: Define the interface for the `modules/ec2-docker-compose` Terraform module. Unchanged from 001; root module passes `allowed_cidr` (from override or auto-detection).

## Module Source

```hcl
module "ec2_docker_compose" {
  source = "./modules/ec2-docker-compose"
}
```

## Input Variables (Required)

| Variable | Type | Description |
|----------|------|-------------|
| `allowed_cidr` | string | CIDR block for inbound access (e.g., `"1.2.3.4/32"`) |

## Input Variables (Optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `"us-east-1"` | AWS region |
| `instance_type` | string | `"t3.micro"` | EC2 instance type |
| `root_volume_size_gb` | number | `30` | Root EBS volume size in GB (gp3) |
| `compose_file_path` | string | `"docker-compose.yml"` | Path to Docker Compose file |
| `compose_file_content` | string | (from file) | Raw compose file content (alternative to path) |

## Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `public_ip` | string | no | Public IP of the EC2 instance |
| `instance_id` | string | no | EC2 instance ID |
| `ssh_password` | string | yes | Random password for SSH (ec2-user/ubuntu) |

## Usage Example (Root Module)

```hcl
# Root uses external data (inline script) or override for allowed_cidr
data "external" "deployer_ip" {
  program = ["sh", "-c", "IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null); ..."]
}

locals {
  deployer_cidr = var.allowed_cidr != null ? var.allowed_cidr : "${data.external.deployer_ip.result["ip"]}/32"
}

module "ec2_docker_compose" {
  source = "./modules/ec2-docker-compose"
  allowed_cidr = local.deployer_cidr
  # ... other vars
}
```
