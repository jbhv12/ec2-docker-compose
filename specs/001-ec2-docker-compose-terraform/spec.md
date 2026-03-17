# Feature Specification: EC2 Docker Compose Terraform

**Feature Branch**: `001-ec2-docker-compose-terraform`  
**Created**: 2025-03-17  
**Status**: Draft  
**Input**: User description: "we need to create easy to use terraform project that allows user to quickly start ec2 and run docker compose file on it without too much config. it should only use instance store, not ebs. it should put docker compose yml file in user dir and run it. it should have meaningful defaults. it should have security group that allows incoming traffic only from user's ip and allows ports that are mapped by docker compose file and all outgoing traffic. user can tweak some of the vars like instance type and disk size. it should have public ip."

## Clarifications

### Session 2025-03-17

- Q: What project structure and user interface should the deployment system expose? → A: Simple structure so user can replace docker compose yaml and run terraform to get app running.
- Q: SSH from public IP fails with "Permission denied (publickey)"; user-data uploaded compose but did not run it? → A: Enable PasswordAuthentication in sshd_config via user-data; install Docker Compose plugin from GitHub (not in AL2023 repos); output ssh_username (ec2-user) for SSH connection. All Terraform complexity in a separate module directory. User-facing files: only the Terraform variables file (for optional changes) and the Docker Compose yaml file. Variables file must have sensible defaults and inline comments explaining each variable and its effects.
- Q: What documentation should the project include? → A: README.md with how-to-get-started docs. README must be very descriptive to grab attention on GitHub and encourage users to try it. Must mention that advanced users can use the Terraform module in their own code.
- Q: Instance size and SSH access? → A: Use small instance by default to minimize costs. Do not create key pair; set random password via user_data script and output it with Terraform. Always allow SSH connection (port 22) restricted to deployer IP.
- Q: Instance store vs EBS for cost? → A: Cost is the priority. Use small instance with EBS if cheaper than instance store (t3.micro + EBS is ~9× cheaper than c5d.large).
- Q: How should deployer IP (allowed_cidr) be determined? → A: Run `curl -s ifconfig.me` by default in a script; user can optionally override via variable.
- Q: Always getting wrong password error? → A: Use alphanumeric-only random password; special characters can break chpasswd or shell/base64 handling.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Deployment with Defaults (Priority: P1)

A user replaces the Docker Compose yaml file with their own and runs Terraform. With minimal or no configuration changes, they receive a cloud compute instance with a public IP where the Compose stack is running. Storage uses EBS root volume (cost-optimized; small instance by default). The deployment completes successfully and the user can access their services. The project structure is simple: user edits only the compose file and optionally the variables file.

**Why this priority**: This is the core value—getting from "I have a compose file" to "it is running in the cloud" with minimal friction.

**Independent Test**: Replace the compose file, run Terraform with no configuration (deployer IP auto-detected via script); verify instance is reachable via public IP and compose services are running. README provides clear get-started steps.

**Acceptance Scenarios**:

1. **Given** a valid Docker Compose file in the project, **When** the user runs Terraform with default configuration, **Then** a compute instance is provisioned with a public IP and the compose stack runs successfully.
2. **Given** the deployment has completed, **When** the user connects to the public IP on ports exposed by the compose file, **Then** the services respond as expected.
3. **Given** the deployment completes, **When** the instance is provisioned, **Then** the compose stack runs on the instance (EBS root by default for cost).

---

### User Story 2 - Customize Instance Resources (Priority: P2)

A user needs different compute or storage capacity. They edit the Terraform variables file to override instance type and disk size (instance store capacity). The deployment uses these values instead of defaults. The variables file includes comments guiding them on each variable and its effects.

**Why this priority**: Flexibility for different workloads; defaults cover common cases, customization covers the rest.

**Independent Test**: Deploy with overridden instance type and disk size; verify the provisioned instance matches the requested resources.

**Acceptance Scenarios**:

1. **Given** the user sets instance type and disk size variables, **When** the deployment runs, **Then** the instance is provisioned with the specified instance type and storage capacity.
2. **Given** the user does not set these variables, **When** the deployment runs, **Then** sensible defaults are used.

---

### User Story 3 - Secure Network Access (Priority: P3)

A user deploys and expects network security: incoming traffic is restricted to their own IP and to the ports exposed by the Docker Compose file; all outgoing traffic is allowed.

**Why this priority**: Security is essential but follows the core deployment flow; users expect safe defaults.

**Independent Test**: Deploy and verify that only the deployer's IP can reach the mapped ports; verify outbound connectivity from the instance.

**Acceptance Scenarios**:

1. **Given** the deployment has completed, **When** a connection attempt comes from the deployer's IP to a port mapped by the compose file, **Then** the connection succeeds.
2. **Given** the deployment has completed, **When** a connection attempt comes from a different IP to a mapped port, **Then** the connection is denied.
3. **Given** the instance is running, **When** services on the instance make outbound requests, **Then** outbound traffic is allowed.

---

### Edge Cases

- What happens when the user's IP changes (e.g., dynamic ISP) during or after deployment? Re-deployment or variable update refreshes the allowed IP.
- How does the system handle an invalid or malformed Docker Compose file? Deployment fails with a clear, actionable error message.
- What happens when the user specifies an unsupported instance type? Deployment fails with a clear error.
- How does the system handle a compose file that maps no ports? Incoming rules allow only the deployer's IP; no additional port rules are added.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The deployment system MUST provision a cloud compute instance with a public IP address.
- **FR-002**: The deployment system MUST use cost-optimized storage; small instance with EBS root by default (cheaper than instance-store instances).
- **FR-003**: The deployment system MUST copy the user's Docker Compose file to the instance and run it in the default user directory. Docker Compose plugin MUST be installed (e.g., from GitHub releases on AL2023 where it is not in default repos).
- **FR-004**: The deployment system MUST provide meaningful defaults so a user can deploy with minimal configuration.
- **FR-005**: The deployment system MUST restrict incoming traffic to the deployer's IP address and to port 22 (SSH) and ports mapped by the Docker Compose file.
- **FR-006**: The deployment system MUST allow all outgoing traffic from the instance.
- **FR-007**: The deployment system MUST allow the user to override instance type and disk size via configuration variables.
- **FR-016**: The deployment system MUST NOT create or require an SSH key pair; MUST set a random alphanumeric-only password for the default user via user_data, enable PasswordAuthentication in sshd, and output the password and SSH username via Terraform.
- **FR-017**: The deployment system MUST use a small instance type by default to minimize costs.
- **FR-008**: The deployment system MUST auto-detect the deployer's IP by default (e.g., via `curl -s ifconfig.me` in a wrapper script) and MUST allow the user to optionally override it via a variable.
- **FR-009**: The deployment system MUST parse the Docker Compose file to determine which host ports to allow in the security group.
- **FR-010**: The project MUST have a simple structure: the user interacts only with the Docker Compose yaml file and the Terraform variables file.
- **FR-011**: All Terraform complexity (resources, logic, modules) MUST be encapsulated in a separate module directory; the user-facing root exposes only the variables file and compose file.
- **FR-012**: The Terraform variables file MUST have sensible defaults and inline comments explaining each variable and its effects.
- **FR-013**: The project MUST include a README.md with how-to-get-started documentation.
- **FR-014**: The README MUST be descriptive and engaging to attract attention on GitHub and encourage users to try the project.
- **FR-015**: The README MUST document that advanced users can use the Terraform module in their own code.

### Key Entities

- **Compute Instance**: A single cloud VM with public IP, EBS root storage, and Docker runtime; hosts the Compose stack.
- **Docker Compose File**: User-provided definition of services and port mappings; determines which ports are exposed.
- **Security Group**: Network rules restricting inbound traffic to deployer IP and mapped ports; allowing all outbound.
- **Configuration Variables**: User-overridable settings (instance type, disk size, deployer IP) with sensible defaults; deployer IP auto-detected by default via script; exposed via a single variables file with comments.
- **Project Root**: User-facing directory containing only the Docker Compose file and Terraform variables file; Terraform module lives in a separate subdirectory.
- **README**: Primary documentation file; includes get-started guide, engaging description for GitHub visibility, and guidance for advanced users who wish to consume the module in their own Terraform code.

## Assumptions

- The deployer has valid cloud credentials and permissions to create instances, security groups, and related resources.
- The deployer's IP is auto-detected by default (e.g., `curl -s ifconfig.me` in a wrapper script); user can override via variable.
- Default instance type (t3.micro) and EBS root minimize cost; user can override for more capacity.
- The default user directory on the instance is the standard home directory for the default OS user (e.g., ec2-user, ubuntu).
- The deployment deliverable is a Terraform project as explicitly requested by the user.
- Terraform logic is isolated in a module directory; the user-facing root contains only the variables file and Docker Compose file for a simple workflow.
- README serves as the primary onboarding document; advanced users can consume the module in their own Terraform projects.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user familiar with Docker Compose can complete a first deployment in under 10 minutes using only a compose file path and defaults.
- **SC-002**: Deployment succeeds with zero required variables when the user provides only a valid compose file (deployer IP auto-detected by default).
- **SC-003**: Users can override instance type and disk size with a single variable change each.
- **SC-004**: Inbound access is restricted to the deployer's IP and mapped ports only; unauthorized IPs cannot reach mapped ports.
- **SC-005**: The provisioned instance has a public IP and cost-optimized storage (EBS root by default).
- **SC-006**: User workflow requires editing only two files (compose yaml and variables file) to deploy or customize; all Terraform complexity is hidden in the module.
- **SC-007**: README enables a new user to get started and understand both quick-deploy and advanced (module reuse) usage.
