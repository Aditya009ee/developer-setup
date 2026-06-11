#!/bin/bash

# =============================================================================
#   MASTER Developer Setup Script
#   Target OS : Ubuntu 24.04 LTS
#   Installs  : ALL Software for AIML, PHP/Laravel, and MERN Developers
#               + Docker
#   Author    : SysAdmin Script
# =============================================================================

# set -e removed — script continues even if one step fails

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
    echo "   MASTER Developer Environment Setup"
    echo "   Ubuntu 24.04 LTS"
    echo "   AIML + PHP/Laravel + MERN + Docker"
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
LOG_FILE="/var/log/master_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
print_info "Log saved to: $LOG_FILE"

# --------------------------------------------------------------------------- #
#  1. System Update
# --------------------------------------------------------------------------- #
print_step "1/13 — Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget gnupg2 apt-transport-https \
    software-properties-common ca-certificates lsb-release \
    unzip zip git build-essential
print_success "System updated."

# --------------------------------------------------------------------------- #
#  2. Git
# --------------------------------------------------------------------------- #
print_step "2/13 — Installing Git..."
apt-get install -y git
print_success "Git installed: $(git --version)"

# --------------------------------------------------------------------------- #
#  3. Python 3 + pip + venv + Django + AI/ML Packages
# --------------------------------------------------------------------------- #
print_step "3/13 — Installing Python 3, pip, Django and AI/ML packages..."
apt-get install -y python3 python3-pip python3-venv python3-dev
update-alternatives --install /usr/bin/python python /usr/bin/python3 1 || true

pip3 install --break-system-packages \
    django \
    djangorestframework \
    django-cors-headers \
    psycopg2-binary \
    python-dotenv \
    pillow \
    requests \
    numpy \
    pandas \
    matplotlib \
    scikit-learn \
    tensorflow \
    torch \
    torchvision \
    jupyter \
    notebook \
    ipykernel \
    openai \
    langchain \
    fastapi \
    uvicorn

print_success "Python installed: $(python --version)"
print_success "Django installed: $(django-admin --version)"
print_success "All AI/ML packages installed."

# --------------------------------------------------------------------------- #
#  4. PHP 8.3 + Extensions + Composer + Laravel
# --------------------------------------------------------------------------- #
print_step "4/13 — Installing PHP 8.3, Composer and Laravel..."
add-apt-repository ppa:ondrej/php -y
apt-get update -y
apt-get install -y \
    php8.3 php8.3-cli php8.3-fpm php8.3-common \
    php8.3-mysql php8.3-pgsql php8.3-zip php8.3-gd \
    php8.3-mbstring php8.3-curl php8.3-xml \
    php8.3-bcmath php8.3-intl php8.3-tokenizer php8.3-fileinfo

# Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Laravel Installer
composer global require laravel/installer
echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> /etc/profile.d/composer.sh
chmod +x /etc/profile.d/composer.sh

print_success "PHP installed: $(php --version | head -1)"
print_success "Composer installed: $(composer --version)"
print_success "Laravel installer installed."

# --------------------------------------------------------------------------- #
#  5. XAMPP
# --------------------------------------------------------------------------- #
print_step "5/13 — Installing XAMPP..."
XAMPP_VERSION="8.2.12"
XAMPP_FILE="xampp-linux-x64-${XAMPP_VERSION}-0-installer.run"
XAMPP_URL="https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/${XAMPP_VERSION}/${XAMPP_FILE}/download"

wget -q --show-progress -O /tmp/xampp-installer.run "$XAMPP_URL"
chmod +x /tmp/xampp-installer.run
/tmp/xampp-installer.run --unattendedmodeui none --mode unattended
rm -f /tmp/xampp-installer.run

cat > /usr/share/applications/xampp.desktop <<EOF
[Desktop Entry]
Name=XAMPP Control Panel
Exec=sudo /opt/lampp/manager-linux-x64.run
Icon=/opt/lampp/htdocs/favicon.ico
Type=Application
Categories=Development;
EOF
print_success "XAMPP installed at /opt/lampp"

# --------------------------------------------------------------------------- #
#  6. Node.js v20 LTS + npm + Yarn + Global Packages
# --------------------------------------------------------------------------- #
print_step "6/13 — Installing Node.js v20, npm, Yarn..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g yarn nodemon pm2 create-react-app \
    express-generator typescript ts-node \
    eslint prettier concurrently dotenv-cli

print_success "Node.js installed: $(node --version)"
print_success "npm installed: $(npm --version)"
print_success "Yarn installed: $(yarn --version)"

# --------------------------------------------------------------------------- #
#  7. MongoDB 7.0 + Compass
# --------------------------------------------------------------------------- #
print_step "7/13 — Installing MongoDB 7.0..."
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb.gpg

echo "deb [arch=amd64,arm64 signed-by=/etc/apt/trusted.gpg.d/mongodb.gpg] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list

apt-get update -y
apt-get install -y mongodb-org
systemctl enable mongod
systemctl start mongod

# MongoDB Compass
wget -q -O /tmp/mongodb-compass.deb \
    "https://downloads.mongodb.com/compass/mongodb-compass_1.42.2_amd64.deb" || true
apt-get install -y /tmp/mongodb-compass.deb 2>/dev/null || true
rm -f /tmp/mongodb-compass.deb

print_success "MongoDB installed: $(mongod --version | head -1)"
print_success "MongoDB Compass installed."

# --------------------------------------------------------------------------- #
#  8. PostgreSQL 16 + pgAdmin 4
# --------------------------------------------------------------------------- #
print_step "8/13 — Installing PostgreSQL 16 and pgAdmin 4..."
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

echo "deb [signed-by=/etc/apt/trusted.gpg.d/postgresql.gpg] \
https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

apt-get update -y
apt-get install -y postgresql-16 postgresql-client-16 postgresql-contrib-16
systemctl enable postgresql
systemctl start postgresql

# pgAdmin 4
curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgadmin.gpg

echo "deb [signed-by=/etc/apt/trusted.gpg.d/pgadmin.gpg] \
https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" \
    > /etc/apt/sources.list.d/pgadmin4.list

apt-get update -y
apt-get install -y pgadmin4-desktop
print_success "PostgreSQL 16 installed: $(psql --version)"
print_success "pgAdmin 4 installed."

# --------------------------------------------------------------------------- #
#  9. Docker
# --------------------------------------------------------------------------- #
print_step "9/13 — Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker "$REAL_USER"

print_success "Docker installed: $(docker --version)"
print_success "Docker Compose installed: $(docker compose version)"

# --------------------------------------------------------------------------- #
#  10. Visual Studio Code + Extensions
# --------------------------------------------------------------------------- #
print_step "10/13 — Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list

apt-get update -y
apt-get install -y code
print_success "VS Code installed."

print_info "Installing VS Code extensions for: $REAL_USER"
# Python / AIML
sudo -u "$REAL_USER" code --install-extension ms-python.python                    2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-python.pylance                   2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-toolsai.jupyter                  2>/dev/null || true
# PHP / Laravel
sudo -u "$REAL_USER" code --install-extension bmewburn.vscode-intelephense-client 2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension onecentlin.laravel-blade            2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ryannaddy.laravel-artisan           2>/dev/null || true
# MERN
sudo -u "$REAL_USER" code --install-extension dbaeumer.vscode-eslint              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension dsznajder.es7-react-js-snippets     2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension mongodb.mongodb-vscode              2>/dev/null || true
# General
sudo -u "$REAL_USER" code --install-extension ms-azuretools.vscode-docker         2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension github.copilot                      2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension esbenp.prettier-vscode              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension eamodio.gitlens                     2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension mtxr.sqltools                       2>/dev/null || true
print_success "VS Code extensions installed."

# --------------------------------------------------------------------------- #
#  11. Google Chrome
# --------------------------------------------------------------------------- #
print_step "11/13 — Installing Google Chrome..."
wget -q -O /tmp/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/google-chrome.deb
rm -f /tmp/google-chrome.deb
print_success "Google Chrome installed."

# --------------------------------------------------------------------------- #
#  12. Microsoft Teams
# --------------------------------------------------------------------------- #
print_step "12/13 — Installing Microsoft Teams..."
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
#  13. Postman
# --------------------------------------------------------------------------- #
print_step "13/13 — Installing Postman..."
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
echo -e "${GREEN}   ✔  ALL SOFTWARE INSTALLED SUCCESSFULLY!${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "${YELLOW}Installed Software Summary:${NC}"
echo -e "  ${GREEN}✔${NC} Git           : $(git --version)"
echo -e "  ${GREEN}✔${NC} Python        : $(python --version 2>&1)"
echo -e "  ${GREEN}✔${NC} Django        : $(django-admin --version 2>&1)"
echo -e "  ${GREEN}✔${NC} PHP           : $(php --version | head -1)"
echo -e "  ${GREEN}✔${NC} Composer      : $(composer --version 2>&1 | head -1)"
echo -e "  ${GREEN}✔${NC} Laravel       : Installer Ready"
echo -e "  ${GREEN}✔${NC} XAMPP         : /opt/lampp"
echo -e "  ${GREEN}✔${NC} Node.js       : $(node --version)"
echo -e "  ${GREEN}✔${NC} npm           : $(npm --version)"
echo -e "  ${GREEN}✔${NC} MongoDB       : $(mongod --version | head -1)"
echo -e "  ${GREEN}✔${NC} PostgreSQL    : $(psql --version)"
echo -e "  ${GREEN}✔${NC} pgAdmin 4     : Installed"
echo -e "  ${GREEN}✔${NC} Docker        : $(docker --version)"
echo -e "  ${GREEN}✔${NC} VS Code       : Installed"
echo -e "  ${GREEN}✔${NC} Google Chrome : Installed"
echo -e "  ${GREEN}✔${NC} MS Teams      : Installed"
echo -e "  ${GREEN}✔${NC} Postman       : Installed"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "  • Start XAMPP         : sudo /opt/lampp/lampp start"
echo -e "  • New Laravel project : laravel new myproject"
echo -e "  • New React app       : npx create-react-app myapp"
echo -e "  • MongoDB shell       : mongosh"
echo -e "  • PostgreSQL status   : sudo systemctl status postgresql"
echo -e "  • Docker status       : sudo systemctl status docker"
echo -e "  • Log file            : $LOG_FILE"
echo ""
echo -e "${CYAN}Please REBOOT for all changes to take effect.${NC}"
echo -e "${CYAN}============================================================${NC}"
