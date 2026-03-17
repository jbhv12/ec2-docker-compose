# Parse docker-compose.yml to extract host ports for security group
# Format: "HOST:CONTAINER" or "HOST:CONTAINER/PROTOCOL" or "IP:PORT:CONTAINER"

locals {
  compose_content = var.compose_file_content != "" ? var.compose_file_content : file("${path.root}/${var.compose_file_path}")
  compose_raw     = try(yamldecode(local.compose_content), {})

  # Flatten all port strings from services.*.ports
  port_strings = flatten([
    for svc_name, svc in try(local.compose_raw.services, {}) : [
      for p in try(svc.ports, []) : tostring(p)
    ]
  ])

  # Extract host port from each string
  # "8080:80" -> 8080, "0.0.0.0:8080:80" -> 8080, "8080:80/tcp" -> 8080
  host_ports = distinct([
    for p in local.port_strings :
    tonumber(
      element(split(":", split("/", p)[0]), length(split(":", split("/", p)[0])) - 2)
    )
    if length(split(":", split("/", p)[0])) >= 2
  ])
}
