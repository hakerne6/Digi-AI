#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "  Docker & Docker Compose Installer"
echo "========================================="

# Must be root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root or use sudo"
  exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_CODENAME=$VERSION_CODENAME
else
    echo "Cannot detect OS"
    exit 1
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo "Unsupported OS: $OS"
    exit 1
fi

echo "Detected OS: $OS ($VERSION_CODENAME)"

echo "Step 1: Removing old versions..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

echo "Step 2: Installing prerequisites..."
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "Step 3: Adding Docker official GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$OS/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "Step 4: Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
  $VERSION_CODENAME stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Step 5: Installing Docker Engine..."
apt-get update
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "Step 6: Enabling Docker service..."
systemctl enable docker
systemctl start docker

echo "Step 7: Adding current user to docker group..."
if [ -n "${SUDO_USER-}" ]; then
    usermod -aG docker "$SUDO_USER"
    echo "User $SUDO_USER added to docker group"
else
    echo "Run: usermod -aG docker <your-username>"
fi

echo "Step 8: Verifying installation..."
docker --version
docker compose version

echo "========================================="
echo "Docker installation completed successfully!"
echo "Please log out and log back in to apply group changes."
echo "Test with: docker run hello-world"
echo "========================================="