resource "aws_security_group" "ec2_docker" {
  name        = "ec2-docker-compose-${random_id.sg_suffix.hex}"
  description = "Allow SSH and compose-mapped ports from deployer IP"
  vpc_id      = data.aws_vpc.default.id

  # SSH always allowed
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "SSH from deployer"
  }

  # Dynamic rules for compose-mapped ports
  dynamic "ingress" {
    for_each = toset(local.host_ports)
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.allowed_cidr]
      description = "Compose port ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "random_id" "sg_suffix" {
  byte_length = 4
}
