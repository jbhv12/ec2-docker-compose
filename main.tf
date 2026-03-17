provider "aws" {
  region = var.aws_region
}

data "external" "deployer_ip" {
  count = var.allowed_cidr == null ? 1 : 0
  program = ["sh", "-c", <<-EOT
    IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
    [ -z "$IP" ] && { echo 'Could not fetch public IP. Set allowed_cidr in terraform.tfvars.' >&2; exit 1; }
    echo "$IP" | grep -q ':' && { echo 'Deployer IP is IPv6. IPv6 not supported. Use IPv4 network or set allowed_cidr.' >&2; exit 1; }
    printf '{"ip":"%s"}' "$IP"
  EOT
  ]
}

locals {
  deployer_cidr = var.allowed_cidr != null ? var.allowed_cidr : "${data.external.deployer_ip[0].result["ip"]}/32"
}

module "ec2_docker_compose" {
  source = "./modules/ec2-docker-compose"

  allowed_cidr        = local.deployer_cidr
  aws_region          = var.aws_region
  instance_type       = var.instance_type
  root_volume_size_gb = var.root_volume_size_gb
  compose_file_path   = var.compose_file_path
}
