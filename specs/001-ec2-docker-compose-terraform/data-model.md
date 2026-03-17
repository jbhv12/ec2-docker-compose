# Data Model: EC2 Docker Compose Terraform

## Entities

### Module Inputs (Variables)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `"us-east-1"` | AWS region for all resources |
| `instance_type` | string | `"t3.micro"` | EC2 instance type (default minimizes cost) |
| `root_volume_size_gb` | number | `8` | Root EBS volume size in GB (gp3) |
| `allowed_cidr` | string | (from deploy.sh or variable) | CIDR for inbound security group; auto-detected by deploy.sh via `curl -s ifconfig.me`; user can override in terraform.tfvars |
| `compose_file_path` | string | `"docker-compose.yml"` | Path to Docker Compose file (relative to root) |

### Module Outputs

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `public_ip` | string | no | Public IP of the EC2 instance |
| `instance_id` | string | no | EC2 instance ID |
| `ssh_password` | string | yes | Random password for default user (ec2-user/ubuntu) |

### Terraform Resources

| Resource | Purpose |
|----------|---------|
| `aws_instance` | EC2 instance with EBS root (root_block_device), user_data for Docker + compose + password set |
| `aws_security_group` | Inbound: deployer IP + port 22 (SSH) + compose-mapped ports; outbound: all |
| `aws_security_group_rule` | Dynamic rules for port 22 and each parsed port |
| `random_password` | Generate random password for SSH (passed to user_data) |

### Compose File Structure (Parsed)

- **services**: Map of service name → config
- **services.*.ports**: List of strings `"HOST_PORT:CONTAINER_PORT"` or `"HOST_PORT:CONTAINER_PORT/PROTOCOL"`
- **Parsed output**: List of host ports (integers) for security group ingress

### State Transitions

- **Plan**: Terraform validates config, parses compose, computes plan
- **Apply**: Creates resources; instance boots; user_data runs; Docker Compose starts
- **Destroy**: Terminates instance, removes security group

## Validation Rules

- Compose file must be valid YAML with at least one service
- `allowed_cidr` must be valid CIDR (e.g., `x.x.x.x/32`)
- `root_volume_size_gb` must be positive (min 8 GB typical for root)
