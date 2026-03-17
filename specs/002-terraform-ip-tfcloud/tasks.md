# Tasks: Terraform IP Fetch and Optional Terraform Cloud

**Input**: Design documents from `/specs/002-terraform-ip-tfcloud/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in spec; manual verification via terraform plan/apply per quickstart.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Repository root: `modules/`, `main.tf`, `variables.tf`, etc.
- No separate script file; inline shell in Terraform `data "external"` block

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Terraform wiring for IP fetch using inline script; blocks all user stories until complete

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T001 Add data "external" "deployer_ip" to main.tf with inline program = ["sh", "-c", "..."]. Inline script must: (1) fetch IP via curl ifconfig.me (fallback icanhazip.com), (2) if empty exit 1 with stderr "Could not fetch public IP. Set allowed_cidr in terraform.tfvars.", (3) if IP contains ":" exit 1 with stderr "Deployer IP is IPv6. IPv6 not supported. Use IPv4 network or set allowed_cidr.", (4) else output JSON {"ip":"$IP"} to stdout
- [x] T002 Add local.deployer_cidr to main.tf: use var.allowed_cidr when set, else data.external.deployer_ip.result["ip"]/32
- [x] T003 Pass local.deployer_cidr to module ec2_docker_compose as allowed_cidr in main.tf (replace var.allowed_cidr)
- [x] T004 Make allowed_cidr optional (default = null) in variables.tf at repository root
- [x] T005 Add variable validation to allowed_cidr in variables.tf: when set, reject IPv6 (condition: var.allowed_cidr == null || !can(regex(":", var.allowed_cidr)); error_message: "allowed_cidr must be IPv4 (no colons). Use x.x.x.x/32 format.")

**Checkpoint**: Foundation ready - Terraform fetches IP via inline script when no override; override validated for IPv4

---

## Phase 2: User Story 1 - Deploy Without External Scripts (Priority: P1) 🎯 MVP

**Goal**: User runs terraform apply directly; no deploy script. IP auto-detected during plan/apply via inline script in Terraform.

**Independent Test**: Run `terraform init && terraform apply` with no terraform.tfvars; verify IP detected, deployment succeeds, security group allows deployer IP only.

### Implementation for User Story 1

- [x] T006 [US1] Remove deploy.sh from repository root (FR-001)
- [x] T007 [US1] Update README.md: remove deploy.sh instructions, document terraform init/terraform apply workflow, remove references to ./deploy.sh
- [x] T008 [US1] Update quickstart.md in specs/002-terraform-ip-tfcloud/quickstart.md: replace deploy.sh steps with terraform init/apply

**Checkpoint**: User Story 1 complete - deployment works with terraform apply only, no deploy script

---

## Phase 3: User Story 2 - Reject IPv6 Deployer IP (Priority: P2)

**Goal**: When detected IP is IPv6, deployment fails with clear error. Override validation rejects IPv6.

**Independent Test**: Simulate IPv6 (e.g., set allowed_cidr to IPv6); verify terraform plan fails with actionable message. Set allowed_cidr="::1/128"; verify variable validation fails.

### Implementation for User Story 2

- [x] T009 [P] [US2] Add IPv6 troubleshooting to README.md: "Deployer IP is IPv6" error, suggest set allowed_cidr override or use IPv4 network
- [x] T010 [P] [US2] Add IPv6 troubleshooting to quickstart.md in specs/002-terraform-ip-tfcloud/quickstart.md

**Checkpoint**: User Story 2 complete - IPv6 rejected by inline script and variable validation; docs explain resolution

---

## Phase 4: User Story 3 - Optional Terraform Cloud (Priority: P3)

**Goal**: User can optionally enable Terraform Cloud for remote state and remote execution.

**Independent Test**: Deploy with no backend (local). Copy backend-cloud.tf.example to backend.tf, configure org/workspace, terraform login, terraform init; verify remote state. Document that allowed_cidr required for remote execution.

### Implementation for User Story 3

- [x] T011 [P] [US3] Create backend-cloud.tf.example at repository root with cloud block (organization, workspaces.name), add comments for user to replace placeholders
- [x] T012 [P] [US3] Add Terraform Cloud section to README.md: how to enable (copy example, terraform login), note that allowed_cidr MUST be set when using remote execution
- [x] T013 [P] [US3] Update quickstart.md in specs/002-terraform-ip-tfcloud/quickstart.md with optional Terraform Cloud steps (section 5)

**Checkpoint**: User Story 3 complete - Terraform Cloud optional; docs explain enable steps and remote execution caveat

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation consistency

- [x] T014 [P] Run terraform fmt on all .tf files
- [x] T015 [P] Run terraform validate
- [x] T016 [P] Update terraform.tfvars.example (if exists) or add example showing optional allowed_cidr = "1.2.3.4/32"
- [x] T017 [P] Verify README.md references quickstart.md or specs/002-terraform-ip-tfcloud/quickstart.md for detailed steps

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies - start immediately (inline script in main.tf)
- **Phase 2 (US1)**: Depends on Phase 1 - remove deploy.sh only after Terraform works
- **Phase 3 (US2)**: Depends on Phase 1 (validation in variables.tf; inline script in Phase 1)
- **Phase 4 (US3)**: Can start after Phase 1 - independent of US1/US2
- **Phase 5 (Polish)**: Depends on Phases 2, 3, 4

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 1; blocks on deploy.sh removal and doc updates
- **User Story 2 (P2)**: Validation in Phase 1; doc updates in Phase 3
- **User Story 3 (P3)**: Independent; backend example and docs

### Within Each Phase

- Phase 1: T001–T005 sequential (main.tf and variables.tf changes)
- Phase 2: T006 (remove deploy.sh) after Phase 1 complete
- Phase 4: T011, T012, T013 can run in parallel (different files)

### Parallel Opportunities

- T009, T010 (US2 docs) can run in parallel
- T011, T012, T013 (US3) can run in parallel
- T014, T015, T016, T017 (Polish) can run in parallel

---

## Parallel Example: User Story 3

```bash
# Launch US3 tasks together:
Task T011: "Create backend-cloud.tf.example"
Task T012: "Add Terraform Cloud section to README.md"
Task T013: "Update quickstart.md with Terraform Cloud steps"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (inline script + Terraform wiring)
2. Complete Phase 2: User Story 1 (remove deploy.sh, update docs)
3. **STOP and VALIDATE**: `terraform init && terraform plan` succeeds with no override
4. Deploy/demo if ready

### Incremental Delivery

1. Foundational → Terraform fetches IP via inline script, override works
2. Add User Story 1 → Remove deploy.sh, docs updated (MVP!)
3. Add User Story 2 → IPv6 docs (inline script/validation already in Phase 1)
4. Add User Story 3 → Terraform Cloud example and docs
5. Polish → fmt, validate, examples

### Task Count Summary

| Phase | Tasks | Story |
|-------|-------|-------|
| Phase 1 | T001–T005 (5) | Foundational |
| Phase 2 | T006–T008 (3) | US1 |
| Phase 3 | T009–T010 (2) | US2 |
| Phase 4 | T011–T013 (3) | US3 |
| Phase 5 | T014–T017 (4) | Polish |
| **Total** | **17** | |

**Suggested MVP scope**: Phases 1, 2 (8 tasks)
