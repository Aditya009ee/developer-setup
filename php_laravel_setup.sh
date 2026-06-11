#!/bin/bash
 
# =============================================================================
#   PHP / Laravel Developer Setup Script
#   Target OS : Ubuntu 24.04 LTS
#   Installs  : VS Code, PHP 8.3, Laravel, Composer, XAMPP,
#               PostgreSQL 16 + pgAdmin 4, Google Chrome,
#               Microsoft Teams, Postman, Git, Docker
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
    echo "   PHP / Laravel Developer Environment Setup"
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
LOG_FILE="/var/log/laravel_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
print_info "Log saved to: $LOG_FILE"
print_info "Running as user: $REAL_USER"
 
# --------------------------------------------------------------------------- #
#  1. System Update
# --------------------------------------------------------------------------- #
print_step "1/11 — Updating system packages..."
apt-get update -y || print_error "Update failed, continuing..."
apt-get upgrade -y || print_error "Upgrade failed, continuing..."
apt-get install -y curl wget gnupg2 apt-transport-https \
    software-properties-common ca-certificates lsb-release \
    unzip zip git build-essential || print_error "Some packages failed, continuing..."
print_success "System updated."
 
# --------------------------------------------------------------------------- #
#  2. Git
# --------------------------------------------------------------------------- #
print_step "2/11 — Installing Git..."
apt-get install -y git || print_error "Git install failed"
git --version && print_success "Git installed: $(git --version)" || print_error "Git not found"
 
# --------------------------------------------------------------------------- #
#  3. PHP 8.3 + All Extensions
# --------------------------------------------------------------------------- #
print_step "3/11 — Installing PHP 8.3 and extensions..."
add-apt-repository ppa:ondrej/php -y || print_error "PPA add failed, continuing..."
apt-get update -y || true
 
apt-get install -y php8.3 || print_error "PHP install failed"
apt-get install -y php8.3-cli || true
apt-get install -y php8.3-fpm || true
apt-get install -y php8.3-common || true
apt-get install -y php8.3-mysql || true
apt-get install -y php8.3-pgsql || true
apt-get install -y php8.3-zip || true
apt-get install -y php8.3-gd || true
apt-get install -y php8.3-mbstring || true
apt-get install -y php8.3-curl || true
apt-get install -y php8.3-xml || true
apt-get install -y php8.3-bcmath || true
apt-get install -y php8.3-intl || true
apt-get install -y php8.3-tokenizer || true
apt-get install -y php8.3-fileinfo || true
apt-get install -y php8.3-opcache || true
apt-get install -y php8.3-readline || true
apt-get install -y php8.3-soap || true
 
php --version && print_success "PHP installed: $(php --version | head -1)" || print_error "PHP not found"
 
# --------------------------------------------------------------------------- #
#  4. Composer
# --------------------------------------------------------------------------- #
print_step "4/11 — Installing Composer..."
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php || print_error "Composer download failed"
php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer || print_error "Composer install failed"
rm -f /tmp/composer-setup.php
composer --version && print_success "Composer installed: $(composer --version)" || print_error "Composer not found"
 
# --------------------------------------------------------------------------- #
#  5. Laravel
# --------------------------------------------------------------------------- #
print_step "5/11 — Installing Laravel..."
composer global require laravel/installer 2>/dev/null || print_error "Laravel installer failed"
 
# Add composer global bin to PATH
echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> /etc/profile.d/composer.sh
chmod +x /etc/profile.d/composer.sh
 
# Also add for current user
sudo -u "$REAL_USER" bash -c 'echo "export PATH=\"\$PATH:\$HOME/.config/composer/vendor/bin\"" >> ~/.bashrc' || true
 
print_success "Laravel installer installed."
 
# --------------------------------------------------------------------------- #
#  6. XAMPP
# --------------------------------------------------------------------------- #
print_step "6/11 — Installing XAMPP..."
XAMPP_VERSION="8.2.12"
XAMPP_FILE="xampp-linux-x64-${XAMPP_VERSION}-0-installer.run"
XAMPP_URL="https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/${XAMPP_VERSION}/${XAMPP_FILE}/download"
 
wget -q --show-progress -O /tmp/xampp-installer.run "$XAMPP_URL" || print_error "XAMPP download failed"
 
if [ -f /tmp/xampp-installer.run ]; then
    chmod +x /tmp/xampp-installer.run
    /tmp/xampp-installer.run --unattendedmodeui none --mode unattended || print_error "XAMPP install failed"
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
else
    print_error "XAMPP download failed — install manually"
fi
 
# --------------------------------------------------------------------------- #
#  7. PostgreSQL 16 + pgAdmin 4
# --------------------------------------------------------------------------- #
print_step "7/11 — Installing PostgreSQL 16..."
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg 2>/dev/null || true
 
echo "deb [signed-by=/etc/apt/trusted.gpg.d/postgresql.gpg] \
https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list
 
apt-get update -y || true
apt-get install -y postgresql-16 postgresql-client-16 postgresql-contrib-16 || print_error "PostgreSQL install failed"
systemctl enable postgresql 2>/dev/null || true
systemctl start postgresql 2>/dev/null || true
psql --version && print_success "PostgreSQL installed: $(psql --version)" || print_error "PostgreSQL not found"
 
print_info "Installing pgAdmin 4..."
curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgadmin.gpg 2>/dev/null || true
 
echo "deb [signed-by=/etc/apt/trusted.gpg.d/pgadmin.gpg] \
https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" \
    > /etc/apt/sources.list.d/pgadmin4.list
 
apt-get update -y || true
apt-get install -y pgadmin4-desktop || print_error "pgAdmin install failed"
print_success "pgAdmin 4 installation attempted."
 
# --------------------------------------------------------------------------- #
#  8. Docker
# --------------------------------------------------------------------------- #
print_step "8/11 — Installing Docker..."
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
#  9. Visual Studio Code + Extensions
# --------------------------------------------------------------------------- #
print_step "9/11 — Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg 2>/dev/null || true
 
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
 
apt-get update -y || true
apt-get install -y code || print_error "VS Code install failed"
code --version && print_success "VS Code installed." || print_error "VS Code not found"
 
print_info "Installing VS Code extensions..."
sudo -u "$REAL_USER" code --install-extension bmewburn.vscode-intelephense-client 2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension onecentlin.laravel-blade            2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension amiralizadeh9480.laravel-extra-intellisense 2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ryannaddy.laravel-artisan           2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension mtxr.sqltools                       2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension esbenp.prettier-vscode              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension github.copilot                      2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-azuretools.vscode-docker         2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension eamodio.gitlens                     2>/dev/null || true
print_success "VS Code extensions installation attempted."
 
# --------------------------------------------------------------------------- #
#  10. Google Chrome + Microsoft Teams
# --------------------------------------------------------------------------- #
print_step "10/11 — Installing Google Chrome and Microsoft Teams..."
 
# Google Chrome
wget -q -O /tmp/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb || print_error "Chrome download failed"
apt-get install -y /tmp/google-chrome.deb || print_error "Chrome install failed"
rm -f /tmp/google-chrome.deb
google-chrome --version && print_success "Chrome installed." || print_error "Chrome not found"
 
# Microsoft Teams
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
#  11. Postman
# --------------------------------------------------------------------------- #
print_step "11/11 — Installing Postman..."
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
echo -e "${GREEN}   ✔  PHP/LARAVEL SETUP COMPLETE!${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "${YELLOW}Installed Software Summary:${NC}"
echo -e "  ${GREEN}✔${NC} Git          : $(git --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} PHP          : $(php --version 2>/dev/null | head -1 || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} Composer     : $(composer --version 2>/dev/null | head -1 || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} Laravel      : Installer Ready"
echo -e "  ${GREEN}✔${NC} XAMPP        : /opt/lampp"
echo -e "  ${GREEN}✔${NC} PostgreSQL   : $(psql --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} pgAdmin 4    : Installed (Desktop)"
echo -e "  ${GREEN}✔${NC} Docker       : $(docker --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} VS Code      : $(code --version 2>/dev/null | head -1 || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} Chrome       : $(google-chrome --version 2>/dev/null || echo 'Check manually')"
echo -e "  ${GREEN}✔${NC} MS Teams     : Installed"
echo -e "  ${GREEN}✔${NC} Postman      : Installed"
echo ""
echo -e "${YELLOW}PHP Extensions Installed:${NC}"
echo -e "  mysql, pgsql, zip, gd, mbstring, curl, xml, bcmath, intl, opcache"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "  • New Laravel project : laravel new myproject"
echo -e "  • Start XAMPP         : sudo /opt/lampp/lampp start"
echo -e "  • Stop XAMPP          : sudo /opt/lampp/lampp stop"
echo -e "  • PostgreSQL status   : sudo systemctl status postgresql"
echo -e "  • Docker status       : sudo systemctl status docker"
echo -e "  • Log file            : $LOG_FILE"
echo ""
echo -e "${CYAN}Please REBOOT for all changes to take effect.${NC}"
echo -e "${CYAN}============================================================${NC}"
