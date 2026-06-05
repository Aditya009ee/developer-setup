#!/bin/bash

# =============================================================================
#   MERN Stack Developer Setup Script
#   Target OS : Ubuntu 24.04 LTS
#   Installs  : VS Code, Node.js, MongoDB, Google Chrome,
#               Microsoft Teams, Postman, Git
#   Author    : SysAdmin Script
# =============================================================================

set -e

# --------------------------------------------------------------------------- #
#  Colors
# --------------------------------------------------------------------------- #
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "============================================================"
    echo "   MERN Stack Developer Environment Setup"
    echo "   Ubuntu 24.04 LTS"
    echo "============================================================"
    echo -e "${NC}"
}
print_step()    { echo -e "\n${BLUE}[STEP]${NC} ${YELLOW}$1${NC}"; }
print_success() { echo -e "${GREEN}[✔]${NC} $1"; }
print_error()   { echo -e "${RED}[✘] ERROR:${NC} $1"; }
print_info()    { echo -e "${CYAN}[i]${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Run as root: sudo bash $0"
        exit 1
    fi
}

print_banner
check_root

LOG_FILE="/var/log/mern_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
print_info "Log saved to: $LOG_FILE"

# --------------------------------------------------------------------------- #
#  1. System Update
# --------------------------------------------------------------------------- #
print_step "1/7 — Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget gnupg2 apt-transport-https \
    software-properties-common ca-certificates lsb-release \
    unzip git build-essential
print_success "System updated."

# --------------------------------------------------------------------------- #
#  2. Git
# --------------------------------------------------------------------------- #
print_step "2/7 — Installing Git..."
apt-get install -y git
print_success "Git installed: $(git --version)"

# --------------------------------------------------------------------------- #
#  3. Node.js (LTS v20) + npm + yarn
# --------------------------------------------------------------------------- #
print_step "3/7 — Installing Node.js LTS (v20) and npm..."

# Official NodeSource repo for Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify
node --version
npm --version

# Install yarn globally
npm install -g yarn

# Install common global packages for MERN
npm install -g \
    nodemon \
    pm2 \
    create-react-app \
    @react-native-community/cli \
    express-generator \
    typescript \
    ts-node \
    eslint \
    prettier \
    concurrently \
    dotenv-cli

print_success "Node.js installed: $(node --version)"
print_success "npm installed: $(npm --version)"
print_success "Yarn installed: $(yarn --version)"
print_success "Global npm packages installed."

# --------------------------------------------------------------------------- #
#  4. MongoDB Community Edition 7.0
# --------------------------------------------------------------------------- #
print_step "4/7 — Installing MongoDB 7.0..."

# Import MongoDB GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb.gpg

# Add MongoDB repo
echo "deb [arch=amd64,arm64 signed-by=/etc/apt/trusted.gpg.d/mongodb.gpg] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list

apt-get update -y
apt-get install -y mongodb-org

# Start and enable MongoDB
systemctl enable mongod
systemctl start mongod

print_success "MongoDB installed: $(mongod --version | head -1)"

# MongoDB Compass (GUI) — optional but useful
print_info "Installing MongoDB Compass (GUI)..."
wget -q -O /tmp/mongodb-compass.deb \
    "https://downloads.mongodb.com/compass/mongodb-compass_1.42.2_amd64.deb" || true
apt-get install -y /tmp/mongodb-compass.deb 2>/dev/null || true
rm -f /tmp/mongodb-compass.deb
print_success "MongoDB Compass installed."

# --------------------------------------------------------------------------- #
#  5. Visual Studio Code
# --------------------------------------------------------------------------- #
print_step "5/7 — Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list

apt-get update -y
apt-get install -y code
print_success "VS Code installed."

REAL_USER="${SUDO_USER:-$USER}"
print_info "Installing VS Code extensions for: $REAL_USER"
# JavaScript / React
sudo -u "$REAL_USER" code --install-extension dbaeumer.vscode-eslint              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension esbenp.prettier-vscode              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension dsznajder.es7-react-js-snippets     2>/dev/null || true
# Node / Express
sudo -u "$REAL_USER" code --install-extension christian-kohler.npm-intellisense   2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension eg2.vscode-npm-script               2>/dev/null || true
# MongoDB
sudo -u "$REAL_USER" code --install-extension mongodb.mongodb-vscode              2>/dev/null || true
# General
sudo -u "$REAL_USER" code --install-extension github.copilot                      2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension eamodio.gitlens                     2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-azuretools.vscode-docker         2>/dev/null || true
print_success "VS Code extensions installed."

# --------------------------------------------------------------------------- #
#  6. Google Chrome + Microsoft Teams
# --------------------------------------------------------------------------- #
print_step "6/7 — Installing Google Chrome and Microsoft Teams..."

# Google Chrome
wget -q -O /tmp/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/google-chrome.deb
rm -f /tmp/google-chrome.deb
print_success "Google Chrome installed."

# Microsoft Teams
wget -q -O /tmp/teams.deb \
    "https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.6.00.4472_amd64.deb" || true

if apt-get install -y /tmp/teams.deb 2>/dev/null; then
    print_success "Microsoft Teams installed."
else
    snap install teams-for-linux 2>/dev/null || true
    print_success "Microsoft Teams installed via snap."
fi
rm -f /tmp/teams.deb

# --------------------------------------------------------------------------- #
#  7. Postman
# --------------------------------------------------------------------------- #
print_step "7/7 — Installing Postman..."
snap install postman 2>/dev/null || {
    wget -q -O /tmp/postman.tar.gz https://dl.pstmn.io/download/latest/linux64
    tar -xzf /tmp/postman.tar.gz -C /opt/
    ln -sf /opt/Postman/Postman /usr/local/bin/postman
    cat > /usr/share/applications/postman.desktop <<EOF
[Desktop Entry]
Name=Postman
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/icons/icon_128x128.png
Type=Application
Categories=Development;
EOF
    rm -f /tmp/postman.tar.gz
}
print_success "Postman installed."

# --------------------------------------------------------------------------- #
#  Summary
# --------------------------------------------------------------------------- #
echo -e "\n${CYAN}============================================================${NC}"
echo -e "${GREEN}   ✔  MERN STACK SETUP COMPLETE!${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "${YELLOW}Installed Software:${NC}"
echo -e "  ${GREEN}✔${NC} Git          : $(git --version)"
echo -e "  ${GREEN}✔${NC} Node.js      : $(node --version)"
echo -e "  ${GREEN}✔${NC} npm          : $(npm --version)"
echo -e "  ${GREEN}✔${NC} Yarn         : $(yarn --version)"
echo -e "  ${GREEN}✔${NC} MongoDB      : $(mongod --version | head -1)"
echo -e "  ${GREEN}✔${NC} MongoDB Compass : Installed (GUI)"
echo -e "  ${GREEN}✔${NC} VS Code      : Installed"
echo -e "  ${GREEN}✔${NC} Chrome       : Installed"
echo -e "  ${GREEN}✔${NC} MS Teams     : Installed"
echo -e "  ${GREEN}✔${NC} Postman      : Installed"
echo ""
echo -e "${YELLOW}Global npm Packages:${NC}"
echo -e "  nodemon, pm2, create-react-app, typescript, eslint, prettier"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "  • New React app       : npx create-react-app myapp"
echo -e "  • New Express app     : express myapp"
echo -e "  • MongoDB status      : sudo systemctl status mongod"
echo -e "  • MongoDB shell       : mongosh"
echo -e "  • MongoDB Compass     : Search in Applications menu"
echo -e "  • Log file            : $LOG_FILE"
echo ""
echo -e "${CYAN}Please REBOOT for all changes to take effect.${NC}"
echo -e "${CYAN}============================================================${NC}"
