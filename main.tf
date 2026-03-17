provider "aws" {
  region = var.aws_region
}

module "ec2_docker_compose" {
  source = "./modules/ec2-docker-compose"

  allowed_cidr        = var.allowed_cidr
  aws_region          = var.aws_region
  instance_type       = var.instance_type
  root_volume_size_gb = var.root_volume_size_gb
  compose_file_path   = var.compose_file_path
}
