# Research: Terraform IP Fetch and Optional Terraform Cloud

## 1. Fetching Deployer Public IP in Terraform

**Decision**: Use Terraform `data "external"` with an inline shell script (program = ["sh", "-c", "..."]) that runs `curl` to fetch the public IP. No separate .sh file. The inline script outputs JSON `{"ip":"x.x.x.x"}` and validates IPv4; if the response is IPv6, the script exits non-zero with an error message to stderr.

**Rationale**: The spec requires IP fetch to happen "as part of the deployment process" without a separate wrapper script. The `external` data source runs during `terraform plan`/`apply` and integrates natively. Inline script avoids adding a scripts/ directory and keeps the logic in one place (main.tf).

**Alternatives considered**:
- Separate scripts/get-deployer-ip.sh: Rejected per user preference; use inline script in Terraform block.
- `data "http"` source: Simpler (no shell), but icanhazip.com/ifconfig.me can return IPv6 when the client is IPv6-only; we'd need to use an IPv4-only service or validate in Terraform. Inline script gives full control over validation and error messages.
- `null_resource` with `local-exec` provisioner: Runs only at apply time, after plan; would require two-phase approach. External data runs at plan time, which is preferable.
- Keep deploy.sh: Rejected per spec; must remove.

## 2. IPv6 Rejection

**Decision**: The inline script checks the fetched IP for the presence of `:` (colon), which indicates IPv6. If detected, the script writes an error to stderr (e.g., "Deployer IP is IPv6. IPv6 not supported. Use an IPv4 network or set allowed_cidr.") and exits with code 1. Terraform surfaces the stderr output to the user.

**Rationale**: AWS security group `cidr_blocks` supports IPv6 via `ipv6_cidr_blocks`, but the spec explicitly requires IPv4-only for deployer access control. Failing in the inline script keeps validation logic in one place and produces a clear, actionable error.

**Alternatives considered**:
- Terraform variable validation with `can(regex(":", ip))`: Would require the IP to be in a variable first; external data source handles it before Terraform sees the value.
- Use `ipv6_cidr_blocks` for IPv6: Rejected per spec; IPv4 only.

## 3. Optional allowed_cidr Override

**Decision**: Make `allowed_cidr` an optional variable with `default = null`. When `null`, use the result of `data.external.deployer_ip`; when set, use the variable. Validate the override with a `validation` block to reject IPv6 (regex for `:`).

**Rationale**: Users can override when auto-detection fails, when using Terraform Cloud remote execution (where the runner's IP would be detected), or when they prefer a fixed CIDR. Validation ensures overrides are also IPv4-only.

**Alternatives considered**:
- Empty string as sentinel: Works but `null` is clearer for "use auto-detection."
- Always require variable: Rejected; spec requires zero-config default.

## 4. Terraform Cloud Backend (Remote State + Remote Execution)

**Decision**: Do not add a `cloud` or `backend` block by default. Provide `backend-cloud.tf.example` (or equivalent) with a `cloud` block that users can copy to `backend.tf` to enable Terraform Cloud. Document in README/quickstart how to enable Terraform Cloud for remote state and remote execution. Remote execution is configured in the Terraform Cloud workspace (Execution Mode: Remote); no Terraform code change needed.

**Rationale**: "Optional" means local state and local execution by default. Users who want Terraform Cloud add the block and run `terraform login`. The `cloud` block (Terraform 1.1+) is the recommended approach; it provides both remote state and optional remote execution via workspace settings.

**Alternatives considered**:
- `backend "remote"` (legacy): Still supported but `cloud` block is preferred.
- Dynamic backend via `-backend-config`: Possible but adds complexity; example file is simpler.
- Require Terraform Cloud: Rejected; must be optional.

## 5. Deployer IP When Using Remote Execution

**Decision**: Document clearly that when using Terraform Cloud remote execution, the detected IP will be the cloud runner's IP, not the user's. Users MUST set `allowed_cidr` in `terraform.tfvars` or as a workspace variable when using remote execution. Add this to README, quickstart, and variable description. No runtime detection of remote execution (Terraform does not expose this reliably in config).

**Rationale**: FR-009 requires "require or clearly document." Runtime enforcement would require detecting TFC remote execution from within Terraform, which is not reliably possible. Documentation is the practical approach; we make it prominent.

**Alternatives considered**:
- Enforce via Sentinel/OPA in TFC: Possible for TFC users but adds policy setup; documentation is sufficient for this project.
- Fail if IP matches known TFC runner ranges: Fragile; ranges can change.

## 6. Inline Script vs Separate File

**Decision**: Use an inline shell script in the Terraform `data "external"` block (program = ["sh", "-c", "..."]) rather than a separate .sh file. The inline script uses `curl` (commonly available) and falls back to `curl -s ifconfig.me` then `curl -s icanhazip.com` if the first fails. Output format: `{"ip":"1.2.3.4"}`.

**Rationale**: User preference: "dont create new sh file for getting ip. use inline script in terraform block itself." Keeps logic in main.tf; no scripts/ directory.

**Alternatives considered**:
- Separate scripts/get-deployer-ip.sh: Rejected per user preference.
- Use only icanhazip.com: Single point of failure; fallback improves resilience.
