# Contract: ec2-docker-compose Terraform Module

**Purpose**: Define the interface for the `modules/ec2-docker-compose` Terraform module. Advanced users consume this module in their own Terraform code.

## Module Source

```hcl
module "ec2_docker_compose" {
  source = "./modules/ec2-docker-compose"
  # or: source = "git::https://github.com/..."
}
```

## Input Variables (Required)

| Variable | Type | Description |
|----------|------|-------------|
| `allowed_cidr` | string | CIDR block for inbound access (e.g., `"1.2.3.4/32"` for deployer IP) |

## Input Variables (Optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `"us-east-1"` | AWS region |
| `instance_type` | string | `"t3.micro"` | EC2 instance type (default minimizes cost) |
| `root_volume_size_gb` | number | `8` | Root EBS volume size in GB (gp3) |
| `compose_file_path` | string | `"docker-compose.yml"` | Path to Docker Compose file |
| `compose_file_content` | string | (from file) | Raw compose file content (alternative to path) |

## Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `public_ip` | string | no | Public IP of the EC2 instance |
| `instance_id` | string | no | EC2 instance ID |
| `ssh_password` | string | yes | Random password for SSH (ec2-user/ubuntu) |

## Usage Example (Advanced Users)

```hcl
module "app" {
  source = "./modules/ec2-docker-compose"

  allowed_cidr   = "${chomp(data.http.myip.response_body)}/32"
  instance_type  = "t3.small"
  aws_region     = "us-west-2"
}

# SSH: ssh ec2-user@$(terraform output -raw public_ip)
# Password: terraform output -raw ssh_password
```
