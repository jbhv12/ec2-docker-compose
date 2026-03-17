# Data Model: Terraform IP Fetch and Optional Terraform Cloud

## Entities

### Root Module Inputs (Variables)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `allowed_cidr` | string | `null` | CIDR for inbound security group. When `null`, auto-detected via external script (curl). When set, overrides auto-detection. Must be IPv4 (e.g., `1.2.3.4/32`). Required when using Terraform Cloud remote execution. |
| `compose_file_path` | string | `"docker-compose.yml"` | Path to Docker Compose file (relative to root) |
| `aws_region` | string | `"us-east-1"` | AWS region |
| `instance_type` | string | `"t3.micro"` | EC2 instance type |
| `root_volume_size_gb` | number | `30` | Root EBS volume size in GB (gp3) |

### Data Sources

| Data Source | Purpose |
|-------------|---------|
| `data.external.deployer_ip` | Runs inline shell script (program = ["sh", "-c", "..."]) at plan time; returns `{"ip":"x.x.x.x"}`. Script fails (exit 1) if IP is IPv6. |
| (existing) `data.aws_ami`, `data.aws_vpc` | Unchanged from 001 |

### Derived Values (Locals)

| Local | Logic |
|-------|-------|
| `deployer_cidr` | `var.allowed_cidr != null ? "${var.allowed_cidr}" : "${data.external.deployer_ip.result["ip"]}/32"` — use override or auto-detected IP with /32 |

### Module Inputs (Passed to ec2-docker-compose)

| Variable | Source |
|----------|--------|
| `allowed_cidr` | `local.deployer_cidr` (from override or external data) |
| (others) | Unchanged from 001 |

### Backend Configuration

| Configuration | When | Behavior |
|---------------|------|----------|
| No `backend` or `cloud` block | Default | Local state in `terraform.tfstate`; local execution |
| `cloud` block (from backend-cloud.tf.example) | User copies to backend.tf | Remote state in Terraform Cloud; remote execution if workspace set to "Remote" |

### Validation Rules

- `allowed_cidr` override: When set, must not contain `:` (IPv6). Use variable `validation` block with `can(regex("^[^:]+$", var.allowed_cidr))` or equivalent to reject IPv6.
- Inline script output: Must be valid JSON `{"ip":"..."}`; script enforces IPv4 before output.
- Compose file: Unchanged from 001 (valid YAML, at least one service).

### State Transitions

- **Plan**: Terraform runs external script (if no override), validates IP, computes plan.
- **Apply**: Creates/updates resources; same as 001.
- **Destroy**: Same as 001.
- **Terraform Cloud**: When cloud block present, plan/apply may run remotely; state stored in TFC.
