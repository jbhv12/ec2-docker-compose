data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "random_password" "ssh_password" {
  length  = 16
  special = false # Alphanumeric only; special chars can break chpasswd/shell handling
}

resource "aws_instance" "ec2_docker" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_docker.id]
  user_data_base64 = base64encode(templatefile("${path.module}/user-data.yaml.tpl", {
    base64_creds   = base64encode("ec2-user:${random_password.ssh_password.result}")
    compose_base64 = base64encode(local.compose_content)
  }))
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
  }

  associate_public_ip_address = true

  tags = {
    Name = "ec2-docker-compose"
  }
}
