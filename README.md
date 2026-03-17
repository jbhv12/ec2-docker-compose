# EC2 Docker Compose

**Deploy your Docker Compose stack to AWS EC2 in minutes.** Replace the compose file, run Terraform, and get a running instance with your services—no complex setup.

## Why This?

- **Simple**: Two files to edit—`docker-compose.yml` and optionally `terraform.tfvars`
- **Cost-optimized**: t3.micro by default (~$0.01/hr)
- **Secure**: Inbound traffic restricted to your IP; SSH with auto-generated password
- **No key pair**: Password set automatically and output by Terraform

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) 1.x
- [AWS CLI](https://aws.amazon.com/cli/) configured (or `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`)

### Steps

1. **Replace the compose file**

   ```bash
   # Edit docker-compose.yml with your services
   ```

2. **Deploy (zero config—IP auto-detected)**

   ```bash
   terraform init
   ./deploy.sh
   ```

   The `deploy.sh` script auto-detects your public IP. No terraform.tfvars needed.

   **Override IP**: Create `terraform.tfvars` with `allowed_cidr = "YOUR_IP/32"` or set `ALLOWED_CIDR` env var.

4. **Access**

   ```bash
   terraform output public_ip
   terraform output ssh_username       # ec2-user
   terraform output -raw ssh_password  # For SSH (password auth)
   ```

   Connect to your services on the ports in your compose file. SSH with password:
   `ssh $(terraform output -raw ssh_username)@$(terraform output -raw public_ip)`

## Customization

Edit `terraform.tfvars` or `variables.tf`:

| Variable | Default | Effect |
|----------|---------|--------|
| `instance_type` | t3.micro | EC2 instance size |
| `root_volume_size_gb` | 30 | Root disk size (GB); min 30 for AL2023 |
| `aws_region` | us-east-1 | AWS region |

## Advanced: Use the Module

You can use the Terraform module in your own code:

```hcl
module "app" {
  source = "./modules/ec2-docker-compose"

  allowed_cidr   = "${chomp(data.http.myip.response_body)}/32"
  instance_type  = "t3.small"
  aws_region     = "us-west-2"
}

output "public_ip" { value = module.app.public_ip }
output "ssh_password" { value = module.app.ssh_password; sensitive = true }
```

## Destroy

```bash
terraform destroy
```

## License

MIT
