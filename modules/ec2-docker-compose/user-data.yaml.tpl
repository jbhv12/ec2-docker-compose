#!/bin/bash
set -e

# Set password and enable SSH password auth (AL2023 disables it by default)
echo "${base64_creds}" | base64 -d | chpasswd
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Install Docker (Amazon Linux 2023)
dnf update -y
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose plugin (not in AL2023 default repos)
mkdir -p /usr/libexec/docker/cli-plugins
curl -sSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Write compose file (base64 avoids delimiter/special char issues)
mkdir -p /home/ec2-user
echo "${compose_base64}" | base64 -d > /home/ec2-user/docker-compose.yml
chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

# Run docker compose
cd /home/ec2-user
docker compose up -d
