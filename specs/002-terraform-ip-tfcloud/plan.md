# Implementation Plan: Terraform IP Fetch and Optional Terraform Cloud

**Branch**: `002-terraform-ip-tfcloud` | **Date**: 2026-03-17 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/002-terraform-ip-tfcloud/spec.md`

## Summary

Remove deploy.sh and move deployer IP detection into Terraform using `data "external"` with an inline shell script (no separate .sh file). The inline script fetches public IP via curl, rejects IPv6 with a clear error, and outputs JSON. Make `allowed_cidr` optional (default null) with override support. Add optional Terraform Cloud backend via `backend-cloud.tf.example` (remote state and remote execution). Document that users must set `allowed_cidr` when using Terraform Cloud remote execution.

## Technical Context

**Language/Version**: HCL (Terraform 1.x), Terraform AWS provider 5.x  
**Primary Dependencies**: hashicorp/aws provider, hashicorp/random, external data source (built-in)  
**Storage**: EBS root volume (unchanged); Terraform state local by default, optional Terraform Cloud  
**Testing**: terraform validate, terraform plan (dry-run), manual deploy verification  
**Target Platform**: AWS EC2 (us-east-1 default); Terraform runs locally or in Terraform Cloud  
**Project Type**: Infrastructure-as-code (Terraform module + root)  
**Performance Goals**: Deployment completes within 5–10 minutes; IP fetch within seconds  
**Constraints**: IPv4-only for deployer CIDR; Terraform Cloud optional  
**Scale/Scope**: Single EC2 instance per deployment; one compose stack per instance  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Code Quality**: terraform fmt; consistent HCL style; external script follows shell best practices
- **User Friendliness**: Zero required variables (IP auto-detected); clear error messages for IPv6 and fetch failures; documented override for Terraform Cloud remote execution
- **CI/CD & IaC**: Terraform as IaC; optional Terraform Cloud for remote state and execution
- **Documentation**: README updated; quickstart.md; backend-cloud.tf.example with comments; variable descriptions

## Project Structure

### Documentation (this feature)

```text
specs/002-terraform-ip-tfcloud/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── module-interface.md
│   └── root-deployment.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
├── modules/
│   └── ec2-docker-compose/  # Unchanged
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── security-group.tf
│       ├── user-data.yaml.tpl
│       ├── compose-parser.tf
│       └── versions.tf
├── main.tf                   # Modified: add data external with inline script, local.deployer_cidr
├── variables.tf              # Modified: allowed_cidr optional (default null)
├── outputs.tf
├── versions.tf
├── backend-cloud.tf.example  # NEW: Terraform Cloud cloud block example
├── terraform.tfvars.example
├── docker-compose.yml
└── README.md                 # Modified: remove deploy.sh, add Terraform Cloud instructions
```

**Structure Decision**: Root contains module call, variables, outputs. The external data source uses an inline shell script (program = ["sh", "-c", "..."]) at plan time—no separate .sh file. No deploy.sh. `backend-cloud.tf.example` provides optional Terraform Cloud configuration; users copy to `backend.tf` to enable.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
