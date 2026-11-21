# Sovrack Universal Installer

Official automated installation script for **Sovrack** — The Open-Core Deployment & Orchestration Platform.

## ⚡ Quickstart

Install Sovrack on any clean Ubuntu 22.04 / 24.04 LTS server with one command:

```bash
curl -fsSL https://get.sovrack.com | bash
```

## 🔒 Security & Verification

Before running any script piped into bash, you can inspect its source code:

```bash
curl -fsSL https://raw.githubusercontent.com/sovrack/installer/main/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh
```

## 🛠️ What the Installer Does

1. **System Check**: Verifies that your distribution is Ubuntu 22.04+ or Debian 12+.
2. **Container Engine**: Installs official Docker Engine and Compose plugin if missing.
3. **Configuration**: Creates `/etc/sovrack/` with auto-generated 256-bit encryption keys and database secrets.
4. **Service Startup**: Launches the Sovrack orchestrator, API, and web interface.
