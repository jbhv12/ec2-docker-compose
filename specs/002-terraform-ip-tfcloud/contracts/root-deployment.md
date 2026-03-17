# Contract: Root Deployment (User-Facing)

**Purpose**: Define the user-facing interface for deploying EC2 Docker Compose. No deploy.sh; Terraform fetches IP via inline script in data external block.

## Commands

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize Terraform; required before first plan/apply |
| `terraform plan` | Preview changes; runs IP fetch script if no override |
| `terraform apply` | Apply changes; creates/updates EC2 and security group |
| `terraform destroy` | Destroy all resources |

## Root Variables

| Variable | Type | Default | Required | Description |
|---------|------|---------|----------|-------------|
| `allowed_cidr` | string | `null` | No | When null, IP auto-detected. When set, overrides auto-detection. Must be IPv4 (e.g., `1.2.3.4/32`). **Required when using Terraform Cloud remote execution.** |
| `compose_file_path` | string | `"docker-compose.yml"` | No | Path to Docker Compose file |
| `aws_region` | string | `"us-east-1"` | No | AWS region |
| `instance_type` | string | `"t3.micro"` | No | EC2 instance type |
| `root_volume_size_gb` | number | `30` | No | Root EBS volume size in GB |

## Backend Options

| Option | How to Enable | State | Execution |
|-------|--------------|-------|-----------|
| Local (default) | No backend block | `terraform.tfstate` in repo | Local |
| Terraform Cloud | Copy `backend-cloud.tf.example` to `backend.tf`, run `terraform login` | Remote | Local or Remote (workspace setting) |

## Error Conditions

| Condition | User Message |
|-----------|--------------|
| Fetched IP is IPv6 | "Deployer IP is IPv6. IPv6 is not supported. Use an IPv4 network or set allowed_cidr in terraform.tfvars." |
| IP fetch fails (no network) | Script stderr: "Could not fetch public IP. Set allowed_cidr in terraform.tfvars or check network." |
| Override is IPv6 | Variable validation: "allowed_cidr must be IPv4 (no colons)." |
