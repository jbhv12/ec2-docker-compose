# Implementation Plan: EC2 Docker Compose Terraform

**Branch**: `001-ec2-docker-compose-terraform` | **Date**: 2025-03-17 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/001-ec2-docker-compose-terraform/spec.md`

## Summary

Terraform project that provisions an EC2 instance, copies the user's Docker Compose file to the instance, and runs it. Simple user-facing structure: only `terraform.tfvars` (or `variables.tf` with defaults) and `docker-compose.yml`. All Terraform logic lives in a `modules/` directory. **Zero required variables**: deployer IP auto-detected via wrapper script (`curl -s ifconfig.me`); user can optionally override. Security group restricts inbound traffic to deployer IP; always allows SSH (port 22) and ports mapped by the compose file; all outbound allowed. Cost-optimized: t3.micro with EBS root by default. No key pair: random password set via user_data, output by Terraform. Default region us-east-1, overridable. Assumes user has AWS credentials with permissions to create required resources.

## Technical Context

**Language/Version**: HCL (Terraform 1.x), Terraform AWS provider 5.x  
**Primary Dependencies**: hashicorp/aws provider, hashicorp/random (for password)  
**Storage**: EBS root volume (default 8 GB gp3); t3.micro/small for cost minimization  
**Testing**: terraform validate, terraform plan (dry-run), manual deploy verification  
**Target Platform**: AWS EC2 (us-east-1 default, region overridable)  
**Project Type**: Infrastructure-as-code (Terraform module + root + wrapper script)  
**Performance Goals**: Deployment completes within 5–10 minutes  
**Constraints**: Cost-optimized; user provides AWS creds with full resource-creation permissions  
**Scale/Scope**: Single EC2 instance per deployment; one compose stack per instance  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Code Quality**: terraform fmt; consistent HCL style; module structure enforces separation
- **User Friendliness**: Zero required variables (IP auto-detected); variables file with comments; random password output; clear error messages
- **CI/CD & IaC**: Terraform as IaC; optional CI for terraform validate/plan (deferred to later phase)
- **Documentation**: README.md with get-started; quickstart.md; variables file comments; advanced users can consume module

## Project Structure

### Documentation (this feature)

```text
specs/001-ec2-docker-compose-terraform/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Source Code (repository root)

```text
├── deploy.sh              # Wrapper: auto-detect IP, run terraform apply
├── modules/
│   └── ec2-docker-compose/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── security-group.tf
│       ├── user-data.yaml.tpl
│       ├── compose-parser.tf
│       └── versions.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
├── docker-compose.yml
└── README.md
```

**Structure Decision**: Root contains module call, variables, outputs, example compose, README, and `deploy.sh` wrapper script. The wrapper runs `curl -s ifconfig.me` to get deployer IP and passes it to Terraform; user can override via `terraform.tfvars` or `-var`. No key pair; SSH uses password auth.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
