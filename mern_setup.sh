#!/bin/bash
 
# =============================================================================
#   MERN Stack Developer Setup Script
#   Target OS : Ubuntu 24.04 LTS
#   Installs  : VS Code, Node.js, MongoDB, MongoDB Compass,
#               npm, yarn, nodemon, Express Generator,
#               Google Chrome, Microsoft Teams, Postman, Git, Docker
#   Author    : SysAdmin Script
# =============================================================================
 
# NO set -e — script will continue even if one step fails
 
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
 
REAL_USER="${SUDO_USER:-$USER}"
LOG_FILE="/var/log/mern_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
print_info "Log saved to: $LOG_FILE"
print_info "Running as user: $REAL_USER"
 
# --------------------------------------------------------------------------- #
#  1. System Update
# --------------------------------------------------------------------------- #
print_step "1/10 — Updating system packages..."
apt-get update -y || print_error "Update failed, continuing..."
apt-get upgrade -y || print_error "Upgrade failed, continuing..."
apt-get install -y curl wget gnupg2 apt-transport-https \
    software-properties-common ca-certificates lsb-release \
    unzip git build-essential || print_error "Some packages failed, continuing..."
print_success "System updated."
 
# --------------------------------------------------------------------------- #
#  2. Git
# --------------------------------------------------------------------------- #
print_step "2/10 — Installing Git..."
apt-get install -y git || print_error "Git install failed"
git --version && print_success "Git installed: $(git --version)" || print_error "Git not found"
 
# --------------------------------------------------------------------------- #
#  3. Node.js v20 LTS + npm + yarn + Global Packages
# --------------------------------------------------------------------------- #
print_step "3/10 — Installing Node.js v20, npm, yarn..."
 
# Add NodeSource repo
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || print_error "NodeSource setup failed"
apt-get install -y nodejs || print_error "Node.js install failed"
 
node --version && print_success "Node.js installed: $(node --version)" || print_error "Node.js not found"
npm --version && print_success "npm installed: $(npm --version)" || print_error "npm not found"
 
# Install yarn
npm install -g yarn 2>/dev/null || print_error "Yarn install failed"
yarn --version && print_success "Yarn installed: $(yarn --version)" || print_error "Yarn not found"
 
# Install global packages
print_info "Installing global npm packages..."
npm install -g nodemon 2>/dev/null || print_error "nodemon install failed"
npm install -g express-generator 2>/dev/null || print_error "express-generator install failed"
npm install -g pm2 2>/dev/null || true
npm install -g create-react-app 2>/dev/null || true
npm install -g typescript 2>/dev/null || true
npm install -g ts-node 2>/dev/null || true
npm install -g eslint 2>/dev/null || true
npm install -g prettier 2>/dev/null || true
npm install -g concurrently 2>/dev/null || true
npm install -g dotenv-cli 2>/dev/null || true
 
nodemon --version && print_success "nodemon installed: $(nodemon --version)" || print_error "nodemon not found"
express --version && print_success "Express Generator installed." || print_error "Express Generator not found"
print_success "All global npm packages installed."
 
# --------------------------------------------------------------------------- #
#  4. MongoDB 7.0 + MongoDB Compass
# --------------------------------------------------------------------------- #
print_step "4/10 — Installing MongoDB 7.0..."
 
# Add MongoDB GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb.gpg 2>/dev/null || true
 
# Add MongoDB repo
echo "deb [arch=amd64,arm64 signed-by=/etc/apt/trusted.gpg.d/mongodb.gpg] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list
 
apt-get update -y || true
apt-get install -y mongodb-org || print_error "MongoDB install failed"
systemctl enable mongod 2>/dev/null || true
systemctl start mongod 2>/dev/null || true
mongod --version && print_success "MongoDB installed: $(mongod --version | head -1)" || print_error "MongoDB not found"
 
# MongoDB Compass
print_info "Installing MongoDB Compass..."
wget -q -O /tmp/mongodb-compass.deb \
    "https://downloads.mongodb.com/compass/mongodb-compass_1.42.2_amd64.deb" || print_error "MongoDB Compass download failed"
 
if [ -f /tmp/mongodb-compass.deb ]; then
    apt-get install -y /tmp/mongodb-compass.deb 2>/dev/null || print_error "MongoDB Compass install failed"
    rm -f /tmp/mongodb-compass.deb
    print_success "MongoDB Compass installed."
else
    print_error "MongoDB Compass download failed — install manually"
fi
 
# --------------------------------------------------------------------------- #
#  5. Docker
# --------------------------------------------------------------------------- #
print_step "5/10 — Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg 2>/dev/null || true
 
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
 
apt-get update -y || true
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || print_error "Docker install failed"
systemctl enable docker 2>/dev/null || true
systemctl start docker 2>/dev/null || true
usermod -aG docker "$REAL_USER" 2>/dev/null || true
docker --version && print_success "Docker installed: $(docker --version)" || print_error "Docker not found"
 
# --------------------------------------------------------------------------- #
#  6. Visual Studio Code + Extensions
# --------------------------------------------------------------------------- #
print_step "6/10 — Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg 2>/dev/null || true
 
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
 
apt-get update -y || true
apt-get install -y code || print_error "VS Code install failed"
code --version && print_success "VS Code installed." || print_error "VS Code not found"
 
print_info "Installing VS Code extensions..."
sudo -u "$REAL_USER" code --install-extension dbaeumer.vscode-eslint              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension esbenp.prettier-vscode              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension dsznajder.es7-react-js-snippets     2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension christian-kohler.npm-intellisense   2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension eg2.vscode-npm-script               2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension mongodb.mongodb-vscode              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension github.copilot                      2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension eamodio.gitlens                     2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-azuretools.vscode-docker         2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension christian-kohler.path-intellisense  2>/dev/null || true
print_success "VS Code extensions installation attempted."
 
# --------------------------------------------------------------------------- #
#  7. Google Chrome
# --------------------------------------------------------------------------- #
print_step "7/10 — Installing Google Chrome..."
wget -q -O /tmp/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb || print_error "Chrome download failed"
apt-get install -y /tmp/google-chrome.deb || print_error "Chrome install failed"
rm -f /tmp/google-chrome.deb
google-chrome --version && print_success "Chrome installed." || print_error "Chrome not found"
 
# --------------------------------------------------------------------------- #
#  8. Microsoft Teams
# --------------------------------------------------------------------------- #
print_step "8/10 — Installing Microsoft Teams..."
wget -q -O /tmp/teams.deb \
    "https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.6.00.4472_amd64.deb" 2>/dev/null || true
 
if apt-get install -y /tmp/teams.deb 2>/dev/null; then
    print_success "Microsoft Teams installed."
else
    snap install teams-for-linux 2>/dev/null || true
    print_success "Microsoft Teams install attempted via snap."
fi
rm -f /tmp/teams.deb
 
# --------------------------------------------------------------------------- #
#  9. Postman
# --------------------------------------------------------------------------- #
print_step "9/10 — Installing Postman..."
snap install postman 2>/dev/null || {
    wget -q -O /tmp/postman.tar.gz https://dl.pstmn.io/download/latest/linux64 || true
    tar -xzf /tmp/postman.tar.gz -C /opt/ 2>/dev/null || true
    ln -sf /opt/Postman/Postman /usr/local/bin/postman 2>/dev/null || true
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
print_success "Postman installation attempted."
 
# --------------------------------------------------------------------------- #
#  Summary
# --------------------------------------------------------------------------- #
echo -e "\n${CYAN}============================================================${NC}"
echo -e "${GREEN}   ✔  MERN STACK SETUP COMPLETE!${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "${YELLOW}Installed Software Summary:${NC}"
echo -e "  ${GREEN}✔${NC} Git              : $(git --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} Node.js          : $(node --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} npm              : $(npm --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} yarn             : $(yarn --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} nodemon          : $(nodemon --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} Express Generator: Installed"
echo -e "  ${GREEN}✔${NC} MongoDB          : $(mongod --version 2>/dev/null | head -1 || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} MongoDB Compass  : Installed"
echo -e "  ${GREEN}✔${NC} Docker           : $(docker --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} VS Code          : $(code --version 2>/dev/null | head -1 || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} Chrome           : $(google-chrome --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} MS Teams         : Installed"
echo -e "  ${GREEN}✔${NC} Postman          : Installed"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "  • New React app    : npx create-react-app myapp"
echo -e "  • New Express app  : express myapp"
echo -e "  • MongoDB status   : sudo systemctl status mongod"
echo -e "  • MongoDB shell    : mongosh"
echo -e "  • Docker status    : sudo systemctl status docker"
echo -e "  • Log file         : $LOG_FILE"
echo ""
echo -e "${CYAN}Please REBOOT for all changes to take effect.${NC}"
echo -e "${CYAN}============================================================${NC}"
