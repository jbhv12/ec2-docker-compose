# Tasks: EC2 Docker Compose Terraform

**Input**: Design documents from `/specs/001-ec2-docker-compose-terraform/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in spec; manual verification via quickstart.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Terraform root**: `main.tf`, `variables.tf`, `outputs.tf`, `docker-compose.yml`, `README.md` at repository root
- **Module**: `modules/ec2-docker-compose/` for all Terraform logic

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Terraform structure

- [x] T001 Create project structure: `modules/ec2-docker-compose/` directory and root `main.tf`, `variables.tf`, `outputs.tf` stubs
- [x] T002 Create `modules/ec2-docker-compose/versions.tf` with required_providers (hashicorp/aws, hashicorp/random)
- [x] T003 [P] Create `terraform.tfvars.example` with `allowed_cidr` placeholder and comments

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core module components that MUST be complete before user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create `modules/ec2-docker-compose/compose-parser.tf` with locals to parse docker-compose YAML and extract host ports from services.*.ports
- [x] T005 Create `modules/ec2-docker-compose/security-group.tf` with aws_security_group: ingress from allowed_cidr for port 22 and parsed compose ports; egress all
- [x] T006 Create `modules/ec2-docker-compose/variables.tf` with required variables: allowed_cidr; optional: aws_region, instance_type, root_volume_size_gb, compose_file_path
- [x] T007 Create `modules/ec2-docker-compose/user-data.tf` (or user_data block) with cloud-init: install Docker, write compose file, set password via chpasswd, run docker compose up -d
- [x] T008 Create `random_password` resource in `modules/ec2-docker-compose/main.tf` and pass to user_data via templatefile

**Checkpoint**: Foundation ready - instance and root wiring can begin

---

## Phase 3: User Story 1 - Quick Deployment with Defaults (Priority: P1) 🎯 MVP

**Goal**: User replaces docker-compose.yml and runs Terraform; receives EC2 with compose stack running and public IP.

**Independent Test**: Replace compose file, run `terraform apply` with defaults; verify instance reachable and compose services running.

### Implementation for User Story 1

- [x] T009 [US1] Create `aws_instance` in `modules/ec2-docker-compose/main.tf` with ami (Amazon Linux 2023), instance_type, root_block_device (size from variable), user_data, associate_public_ip_address
- [x] T010 [US1] Create `modules/ec2-docker-compose/outputs.tf` with public_ip, instance_id, ssh_password (sensitive)
- [x] T011 [US1] Create root `main.tf` invoking module with source = "./modules/ec2-docker-compose" and passing variables
- [x] T012 [US1] Create root `variables.tf` with allowed_cidr, compose_file_path, aws_region (default us-east-1), instance_type (default t3.micro), root_volume_size_gb (default 8)
- [x] T013 [US1] Create root `outputs.tf` forwarding module outputs public_ip, instance_id, ssh_password
- [x] T014 [US1] Create example `docker-compose.yml` with minimal service (e.g., nginx or hello-world) for quickstart validation

**Checkpoint**: User Story 1 complete - deploy with defaults works

---

## Phase 4: User Story 2 - Customize Instance Resources (Priority: P2)

**Goal**: User can override instance type and disk size via variables; variables file has comments explaining each variable.

**Independent Test**: Deploy with overridden instance_type and root_volume_size_gb; verify instance matches.

### Implementation for User Story 2

- [x] T015 [US2] Add inline comments to root `variables.tf` for each variable explaining its effect (instance_type, root_volume_size_gb, aws_region, allowed_cidr, compose_file_path)
- [x] T016 [US2] Add inline comments to `modules/ec2-docker-compose/variables.tf` for each variable
- [x] T017 [US2] Ensure `root_block_device` in `modules/ec2-docker-compose/main.tf` uses root_volume_size_gb variable with volume_type = gp3

**Checkpoint**: User Story 2 complete - customization via variables works

---

## Phase 5: User Story 3 - Secure Network Access (Priority: P3)

**Goal**: Inbound restricted to deployer IP and ports 22 + compose-mapped; outbound all.

**Independent Test**: Deploy and verify only deployer IP can reach mapped ports; outbound works.

### Implementation for User Story 3

- [x] T018 [US3] Verify `modules/ec2-docker-compose/security-group.tf` ingress rules use allowed_cidr for port 22 and each parsed compose port; egress 0.0.0.0/0
- [x] T019 [US3] Add dynamic aws_security_group_rule resources (or inline rules) for each port from compose parser; handle empty ports list

**Checkpoint**: User Story 3 complete - security group correctly restricts access

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and validation

- [x] T020 Create `README.md` with engaging description, get-started steps, prerequisites, and section for advanced users (module reuse in own Terraform)
- [x] T021 Run `terraform fmt -recursive` and fix any formatting
- [x] T022 Validate deployment: run through `specs/001-ec2-docker-compose-terraform/quickstart.md` and confirm all steps work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3–5)**: All depend on Foundational
  - US1 (Phase 3): Core deploy flow
  - US2 (Phase 4): Depends on US1 (variables wiring)
  - US3 (Phase 5): Security group in Foundational; Phase 5 verifies/completes rules
- **Polish (Phase 6)**: Depends on all user stories

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - delivers MVP
- **User Story 2 (P2)**: Extends US1 with variable comments and root_volume_size_gb
- **User Story 3 (P3)**: Security group in Foundational; Phase 5 ensures dynamic port rules complete

### Within Each User Story

- Variables before resources that use them
- Compose parser before security group
- Security group before instance (instance needs sg id)

### Parallel Opportunities

- T003 can run in parallel with T001/T002
- T015 and T016 can run in parallel
- T020 and T021 can run in parallel

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run terraform init, plan, apply; verify compose stack runs
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Module skeleton ready
2. Add User Story 1 → Test deploy with defaults (MVP!)
3. Add User Story 2 → Test customization
4. Add User Story 3 → Verify security rules
5. Polish → README, fmt, quickstart validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to user story for traceability
- No tests requested; use manual quickstart validation
- Commit after each task or logical group
- Ensure `allowed_cidr` is documented (user must set deployer IP)
