# Research: EC2 Docker Compose Terraform

## 1. Storage: Cost Over Instance Store (UPDATED)

**Decision**: Use small EBS-backed instance (t3.micro) by default. Cost is the priority; EBS + t3.micro is significantly cheaper than instance-store instances (c5d.large ~$0.096/hr vs t3.micro ~$0.0104/hr + minimal EBS).

**Rationale**: User input: "cost is concern. we can use small instance with ebs if that is cheaper rather than instance store." t3.micro with 8 GB gp3 EBS root is ~9× cheaper than c5d.large. Overrides original spec preference for instance store only.

**Alternatives considered**:
- Instance store only (c5d.large): Higher cost; rejected for cost priority.
- t3.small: Slightly more capacity, higher cost; t3.micro sufficient for lightweight compose stacks.

## 2. AWS Region

**Decision**: Default region `us-east-1`; user overrides via `aws_region` variable.

**Rationale**: User input specifies us-east-1 as default. Common default for AWS; overridable for multi-region use.

**Alternatives considered**: None; user-specified.

## 3. Deployer IP Detection (UPDATED)

**Decision**: Provide `deploy.sh` wrapper script that runs `curl -s ifconfig.me` and passes `allowed_cidr` to Terraform. `allowed_cidr` variable is optional; when set (terraform.tfvars or -var), it overrides auto-detection. Default workflow: user runs `./deploy.sh` with zero config.

**Rationale**: User input: "instead of asking user to specify allowed_cidr we can just run curl -s ifconfig.me by Default in some script and then allow user to override it optionally." Wrapper script provides zero-config deploy; override via variable for CI, VPN, or different IP.

**Alternatives considered**:
- Terraform data "http" source: Fetches at plan time; adds hashicorp/http provider; wrapper script is simpler and avoids provider dependency.
- Required variable: Rejected; user wants zero config by default.

## 4. Docker Compose Port Parsing

**Decision**: Use Terraform `yamldecode()` + `file()` to read compose file; extract host ports from `services.*.ports` using `regex()` or `flatten()`. Host port format: `"HOST:CONTAINER"` or `"HOST:CONTAINER/PROTOCOL"`.

**Rationale**: Terraform can parse YAML natively. Compose v2/v3 format uses `ports` as list of strings. Extract host port (left side of `:`) for security group rules.

**Alternatives considered**:
- External script: Adds complexity; Terraform yamldecode sufficient.
- User provides ports as variable: Duplicates compose file; rejected for DRY.

## 5. Copy Compose File and Run Docker Compose

**Decision**: Use `user_data` (cloud-init) to install Docker, write compose file from template (content passed from root), and run `docker compose up -d`. Compose file content passed as variable from root (read via `file()`).

**Rationale**: Provisioners (file + remote-exec) require SSH key management and are discouraged by Terraform. User_data/cloud-init runs at boot, no SSH needed for initial setup. Compose file is templated or passed as base64 in user_data.

**Alternatives considered**:
- File + remote-exec provisioners: Require SSH key, more failure modes; Terraform discourages.
- Separate Ansible/Chef: Out of scope; adds tooling.

## 6. AWS Credentials

**Decision**: Assume user has AWS credentials (env vars, ~/.aws/credentials, or IAM role) with permissions to create: EC2 instances, security groups, key pairs, VPC/default VPC access. No explicit credential handling in Terraform.

**Rationale**: User input: "assume user has aws creds with permission to create all resources."

**Alternatives considered**: None.

## 7. Default Instance Type and Disk

**Decision**: Default instance type `t3.micro` (2 vCPU, 1 GB RAM, burstable). Default root EBS volume 8 GB gp3. Variable for instance type and `root_volume_size_gb` for disk.

**Rationale**: Cost minimization. t3.micro (~$0.0104/hr) + 8 GB gp3 is far cheaper than c5d.large. User can override to t3.small or larger if needed. Root volume size is user-configurable.

**Alternatives considered**: c5d.large (instance store, ~9× cost); t3.small (more RAM, higher cost); t3.micro chosen for lowest cost.

## 8. SSH Access: No Key Pair, Random Password

**Decision**: Do not create or use SSH key pair. Use `random_password` resource; pass password to user_data via `templatefile()`; cloud-init runs `chpasswd` to set password for default user (ec2-user/ubuntu). Output password via `terraform output ssh_password`. Mark output as sensitive.

**Rationale**: User input: "dont create key pair. instead set some random password with user script and output that password with terraform."

**Alternatives considered**:
- Key pair: Rejected per user request.
- Secrets Manager: Adds complexity; user requested simple password output.

## 9. SSH Port Always Allowed

**Decision**: Security group ingress always includes port 22 (SSH), restricted to `allowed_cidr` (deployer IP). SSH is allowed alongside compose-mapped ports.

**Rationale**: User input: "always allow ssh connection." Port 22 added to ingress rules with same CIDR restriction as other ports.
