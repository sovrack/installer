#!/usr/bin/env bash
# ==============================================================================
# Sovrack Installation Script
# The Open-Core Deployment & Orchestration Platform
# Website: https://sovrack.com | GitHub: https://github.com/sovrack
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${CYAN}             SOVRACK INSTALLATION SCRIPT             ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. Verify Root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERROR] This script must be run as root (or with sudo).${NC}" >&2
  exit 1
fi

# 2. Verify Supported OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [ "$ID" != "ubuntu" ] && [ "$ID" != "debian" ]; then
    echo -e "${RED}[ERROR] Sovrack currently supports Ubuntu 22.04+ or Debian 12+. Detected: $NAME${NC}" >&2
    exit 1
  fi
else
  echo -e "${RED}[ERROR] Cannot detect operating system release.${NC}" >&2
  exit 1
fi

echo -e "${GREEN}✓ Supported OS detected: $NAME ($VERSION_ID)${NC}"

# 3. Install Prerequisites (curl, git, jq)
echo -e "${CYAN}→ Installing required system packages...${NC}"
apt-get update -qq
apt-get install -y -qq curl git jq ca-certificates gnupg lsb-release

# 4. Install Docker Engine if not present
if ! command -v docker &> /dev/null; then
  echo -e "${CYAN}→ Installing Docker Engine...${NC}"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  echo -e "${GREEN}✓ Docker Engine successfully installed.${NC}"
else
  echo -e "${GREEN}✓ Docker Engine is already installed.$(docker --version)${NC}"
fi

# 5. Create Configuration Directory
SOVRACK_DIR="/etc/sovrack"
mkdir -p "$SOVRACK_DIR"
cd "$SOVRACK_DIR"

# 6. Generate Environment Secrets
if [ ! -f "$SOVRACK_DIR/.env" ]; then
  echo -e "${CYAN}→ Generating secure keys for production...${NC}"
  JWT_SECRET=$(openssl rand -hex 32)
  DB_PASSWORD=$(openssl rand -hex 16)
  ENCRYPTION_KEY=$(openssl rand -hex 32)

  cat <<EOF > "$SOVRACK_DIR/.env"
NODE_ENV=production
PORT=3001
WEB_PORT=3000
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
DATABASE_URL=postgresql://sovrack:${DB_PASSWORD}@postgres:5432/sovrack?schema=public
POSTGRES_USER=sovrack
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=sovrack
EOF
fi

# 7. Download Production Compose Manifest
echo -e "${CYAN}→ Downloading official Sovrack production compose manifest...${NC}"
curl -fsSL https://raw.githubusercontent.com/sovrack/sovrack/main/infra/docker-compose.prod.yml -o "$SOVRACK_DIR/docker-compose.yml"

# 8. Start Sovrack Containers via Docker Compose
echo -e "${CYAN}→ Pulling and starting Sovrack services...${NC}"
docker compose -f "$SOVRACK_DIR/docker-compose.yml" --env-file "$SOVRACK_DIR/.env" pull -q || true
docker compose -f "$SOVRACK_DIR/docker-compose.yml" --env-file "$SOVRACK_DIR/.env" up -d

echo -e "${GREEN}✓ Sovrack configuration generated at $SOVRACK_DIR/.env${NC}"

PUBLIC_IP=$(curl -s -4 https://ifconfig.me || curl -s -4 https://api.ipify.org || echo "YOUR-SERVER-IP")

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}        🎉 SOVRACK WAS INSTALLED SUCCESSFULLY!       ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""
echo -e "Access your Sovrack Web Console at:"
echo -e "👉 ${CYAN}http://${PUBLIC_IP}:3000${NC}"
echo ""
echo -e "Documentation: https://docs.sovrack.com"
echo -e "Community:     https://discord.gg/sovrack"
echo ""
