# Quickstart: Terraform IP Fetch and Terraform Cloud

Get your Docker Compose stack running on EC2 with zero-config IP detection. No deploy script needed.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) 1.x installed
- [AWS CLI](https://aws.amazon.com/cli/) configured (or `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` env vars)
- AWS credentials with permissions to create EC2 instances, security groups

## Steps

### 1. Clone or copy the project

```bash
git clone <repo-url>
cd ec2-docker-compose
```

### 2. Add your Docker Compose file

Replace `docker-compose.yml` with your own, or ensure your compose file is at the path referenced in the variables.

### 3. Deploy (zero config)

Terraform auto-detects your public IP during plan/apply. No terraform.tfvars needed:

```bash
terraform init
terraform apply
```

**Optional override**: To set a specific IP (e.g., for CI, VPN, or Terraform Cloud remote execution), create `terraform.tfvars`:

```hcl
allowed_cidr = "1.2.3.4/32"
```

Or pass on the command line: `terraform apply -var='allowed_cidr=1.2.3.4/32'`.

### 4. Access your app

After apply completes:

```bash
terraform output public_ip
terraform output -raw ssh_password   # Use for SSH login
```

Connect to your services on the ports defined in your Docker Compose file. To SSH:

```bash
ssh ec2-user@$(terraform output -raw public_ip)
# Enter the password from: terraform output -raw ssh_password
```

### 5. (Optional) Enable Terraform Cloud

For remote state and optional remote execution:

1. Create a Terraform Cloud account and organization.
2. Copy the example backend config:
   ```bash
   cp backend-cloud.tf.example backend.tf
   ```
3. Edit `backend.tf` and set your organization and workspace name.
4. Run `terraform login` and authenticate.
5. Run `terraform init` (re-initialize with the new backend).

**Important**: When using Terraform Cloud **remote execution** (plan/apply run in the cloud), you **must** set `allowed_cidr` in terraform.tfvars or as a workspace variable. Auto-detection would return the cloud runner's IP, not yours.

### 6. (Optional) Customize

Edit `terraform.tfvars` or `variables.tf` to override:

- `instance_type` (e.g., `t3.small` for more capacity)
- `root_volume_size_gb` (default 30)
- `aws_region` (default: `us-east-1`)

## Destroy

```bash
terraform destroy
```

## Troubleshooting

- **"Deployer IP is IPv6"**: Your network exposes IPv6 only. Set `allowed_cidr` to an IPv4 address (e.g., from a VPN) in terraform.tfvars.
- **"Could not fetch public IP"**: No outbound internet access or IP services unreachable. Set `allowed_cidr` manually.
- **Invalid compose file**: Ensure `docker-compose.yml` is valid YAML with at least one service.
- **Terraform Cloud remote execution**: Always set `allowed_cidr`; auto-detection returns the runner's IP.
