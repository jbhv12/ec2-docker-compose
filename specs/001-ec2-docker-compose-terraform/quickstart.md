# Quickstart: EC2 Docker Compose Terraform

Get your Docker Compose stack running on EC2 in under 10 minutes.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) 1.x installed
- [AWS CLI](https://aws.amazon.com/cli/) configured (or `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` env vars)
- AWS credentials with permissions to create EC2 instances, security groups, key pairs

## Steps

### 1. Clone or copy the project

```bash
git clone <repo-url>
cd ec2-docker-compose
```

### 2. Add your Docker Compose file

Replace `docker-compose.yml` with your own, or ensure your compose file is at the path referenced in the variables.

### 3. Deploy (zero config)

The `deploy.sh` script auto-detects your IP and runs Terraform. No terraform.tfvars needed:

```bash
terraform init
./deploy.sh      # Auto-detects IP, runs terraform apply
```

**Optional override**: To set a specific IP (e.g., for CI or VPN), create `terraform.tfvars` with `allowed_cidr = "YOUR_IP/32"` or run `terraform apply -var='allowed_cidr=YOUR_IP/32'`.

### 5. Access your app

After apply completes, Terraform outputs the public IP and SSH password:

```bash
terraform output public_ip
terraform output -raw ssh_password   # Use for SSH login
```

Connect to your services on the ports defined in your Docker Compose file. To SSH into the instance:

```bash
ssh ec2-user@$(terraform output -raw public_ip)
# Enter the password from: terraform output -raw ssh_password
```

### 6. (Optional) Customize

Edit `terraform.tfvars` or `variables.tf` to override:

- `instance_type` (e.g., `t3.small` for more capacity; default `t3.micro` minimizes cost)
- `root_volume_size_gb` (default 8; increase for more disk)
- `aws_region` (default: `us-east-1`)

## Destroy

```bash
terraform destroy
```

## Troubleshooting

- **Invalid compose file**: Ensure `docker-compose.yml` is valid YAML and has at least one service.
- **Instance type not supported**: Use common types like t3.micro, t3.small, etc.
- **Connection refused**: Verify `allowed_cidr` includes your current IP (it may change on dynamic connections).
