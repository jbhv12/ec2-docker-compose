# Feature Specification: Terraform IP Fetch and Optional Terraform Cloud

**Feature Branch**: `002-terraform-ip-tfcloud`  
**Created**: 2026-03-17  
**Status**: Draft  
**Input**: User description: "remove the deploy.sh file. use shell executor in terraform to fetch public ip. if public ip is ipv6 it should error out. allow user to optionally use terraform cloud to manage state"

## Clarifications

### Session 2026-03-17

- Q: What Terraform Cloud capabilities should be supported? → A: Both remote state and remote execution (running Terraform in the cloud).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy Without External Scripts (Priority: P1)

A user runs the infrastructure deployment directly without a separate wrapper script. Deployer IP detection happens automatically during the deployment process. The user does not need to run or maintain a deploy script.

**Why this priority**: Simplifies the workflow; removes a file and reduces the number of steps users must understand and execute.

**Independent Test**: Run deployment with no deploy script present; verify deployer IP is detected and used for security rules; deployment completes successfully.

**Acceptance Scenarios**:

1. **Given** no deploy script exists, **When** the user runs the deployment, **Then** the deployer's public IP is detected automatically and used for access control.
2. **Given** the user has not set a deployer IP override, **When** the deployment runs, **Then** the system fetches the public IP as part of the deployment process.
3. **Given** the deployment completes, **When** the user checks access rules, **Then** only the detected deployer IP is allowed for restricted ports.

---

### User Story 2 - Reject IPv6 Deployer IP (Priority: P2)

A user whose network exposes only an IPv6 address as their public IP receives a clear error during deployment. The system does not proceed with an IPv6 deployer address, preventing misconfiguration of security rules that expect IPv4.

**Why this priority**: IPv4-only security rules are common; allowing IPv6 would lead to failed or insecure deployments without clear feedback.

**Independent Test**: Simulate or force deployer IP detection to return IPv6; verify deployment fails with an actionable error message.

**Acceptance Scenarios**:

1. **Given** the detected deployer public IP is IPv6, **When** the deployment runs, **Then** the deployment fails with a clear error indicating IPv6 is not supported.
2. **Given** the error occurs, **When** the user reads the message, **Then** they understand they must use an IPv4 network or provide an override.
3. **Given** the deployer IP is IPv4, **When** the deployment runs, **Then** it proceeds normally.

---

### User Story 3 - Optional Terraform Cloud (Priority: P3)

A user who works in a team or wants cloud-managed infrastructure can optionally enable Terraform Cloud. When enabled, the user gains both remote state storage and the ability to run Terraform (plan/apply) in the cloud instead of locally. When disabled, the default local execution and local state behavior is preserved.

**Why this priority**: Supports collaboration, backup, and remote execution; optional so single users are not forced to create accounts or change workflow.

**Independent Test**: Deploy with Terraform Cloud disabled (default) and with Terraform Cloud enabled (remote state and/or remote execution); verify both paths work.

**Acceptance Scenarios**:

1. **Given** Terraform Cloud is not configured, **When** the user runs deployment locally, **Then** state is stored locally and execution runs on the user's machine.
2. **Given** the user enables Terraform Cloud, **When** they run deployment, **Then** state is stored remotely and optionally execution runs in the cloud.
3. **Given** Terraform Cloud is enabled, **When** a second user runs deployment from a different machine with access to the same workspace, **Then** they see the existing state and can manage the same infrastructure.

---

### Edge Cases

- What happens when the deployer has no outbound internet access to fetch their public IP? Deployment fails with a clear error; user must provide an override.
- How does the system handle a transient failure when fetching the public IP? User receives an actionable error and can retry or provide an override.
- What happens when the user enables Terraform Cloud but has not configured credentials or workspace? Deployment fails with a clear error explaining what is required.
- How does the system behave when switching from local to Terraform Cloud (or vice versa) on an existing deployment? User receives guidance on migration; existing state is not silently lost.
- When Terraform runs in the cloud (remote execution), whose IP is used for deployer IP? The cloud runner's IP would be detected, not the user's. The user MUST provide a deployer IP override when using remote execution so access rules allow the correct address.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The deploy script (deploy.sh) MUST be removed from the project.
- **FR-002**: The deployment system MUST fetch the deployer's public IP as part of the deployment process, without requiring a separate wrapper script.
- **FR-003**: The deployment system MUST fail with a clear, actionable error when the detected deployer public IP is IPv6.
- **FR-004**: The deployment system MUST support IPv4 deployer addresses only for access control.
- **FR-005**: The deployment system MUST allow the user to optionally use Terraform Cloud for remote state and remote execution (running plan/apply in the cloud).
- **FR-006**: When Terraform Cloud is not configured, the deployment system MUST use local state storage and local execution (default behavior).
- **FR-007**: When Terraform Cloud is configured, the deployment system MUST support remote state storage and optionally remote execution as configured by the user.
- **FR-008**: The deployment system MUST allow the user to override the deployer IP when auto-detection fails or when they prefer a manual value.
- **FR-009**: When Terraform runs in the cloud (remote execution), the deployment system MUST require or clearly document that the user provide a deployer IP override, since auto-detection would return the cloud runner's IP rather than the user's.

### Key Entities

- **Deployer IP**: The public IP address of the user running the deployment; used to restrict inbound access. Must be IPv4.
- **Terraform Cloud**: Optional cloud service providing remote state storage and remote execution (plan/apply runs in the cloud); when not used, local state and local execution apply.
- **Deployment Process**: The single workflow that fetches deployer IP, validates it, and applies infrastructure changes.

## Assumptions

- The deployer has outbound internet access to fetch their public IP when not overriding.
- Public IP detection services (e.g., ifconfig.me, icanhazip.com) return the deployer's IPv4 when on an IPv4 network.
- Users on IPv6-only networks will need to provide an IPv4 override (e.g., from a VPN or proxy) or use a different deployment approach.
- Terraform Cloud configuration is optional; users who enable it are responsible for credentials and workspace setup. When using remote execution, the user must provide deployer IP override (auto-detection would return the cloud runner's IP).
- The project continues to use infrastructure-as-code tooling; the removal of deploy.sh does not change the core deployment mechanism.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can complete deployment by running a single command without any deploy script.
- **SC-002**: When deployer IP is IPv6, the user receives an error message within 30 seconds that clearly states IPv6 is not supported and suggests alternatives.
- **SC-003**: Users can choose between local execution and state (default) and Terraform Cloud (remote state and/or remote execution) with a simple configuration change.
- **SC-004**: Deployment succeeds with auto-detected IPv4 deployer IP and no manual configuration in the common case.
- **SC-005**: The project has one fewer file (deploy.sh removed) while preserving all deployment capabilities.
- **SC-006**: Users who enable Terraform Cloud can collaborate on the same infrastructure from multiple machines and optionally run Terraform in the cloud.
