#!/bin/bash

# =============================================================================
#   AIML / Python Developer Setup Script
#   Target OS : Ubuntu 24.04 LTS
#   Installs  : VS Code, Python, Django, PostgreSQL 16 + pgAdmin 4,
#               Google Chrome, Microsoft Teams, Postman, Git
#   Author    : SysAdmin Script (Auto-generated)
# =============================================================================

set -e  # Exit immediately on any error

# --------------------------------------------------------------------------- #
#  Colors for pretty output
# --------------------------------------------------------------------------- #
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --------------------------------------------------------------------------- #
#  Helper functions
# --------------------------------------------------------------------------- #
print_banner() {
    echo -e "${CYAN}"
    echo "============================================================"
    echo "   AIML / Python Developer Environment Setup"
    echo "   Ubuntu 24.04 LTS"
    echo "============================================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}[STEP]${NC} ${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}[✔]${NC} $1"
}

print_error() {
    echo -e "${RED}[✘] ERROR:${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root. Use: sudo bash $0"
        exit 1
    fi
}

# --------------------------------------------------------------------------- #
#  START
# --------------------------------------------------------------------------- #
print_banner
check_root

LOG_FILE="/var/log/aiml_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
print_info "Full log saved to: $LOG_FILE"

# --------------------------------------------------------------------------- #
#  1. System Update
# --------------------------------------------------------------------------- #
print_step "1/9 — Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget gnupg2 apt-transport-https \
    software-properties-common ca-certificates lsb-release \
    unzip git build-essential
print_success "System updated."

# --------------------------------------------------------------------------- #
#  2. Git
# --------------------------------------------------------------------------- #
print_step "2/9 — Installing Git..."
apt-get install -y git
git --version
print_success "Git installed: $(git --version)"

# --------------------------------------------------------------------------- #
#  3. Python 3 + pip + venv
# --------------------------------------------------------------------------- #
print_step "3/9 — Installing Python 3, pip, and venv..."
apt-get install -y python3 python3-pip python3-venv python3-dev
# Make 'python' point to python3
update-alternatives --install /usr/bin/python python /usr/bin/python3 1 || true
python --version
pip3 --version
print_success "Python installed: $(python --version)"

# --------------------------------------------------------------------------- #
#  4. Django + common AIML/ML Python packages
# --------------------------------------------------------------------------- #
print_step "4/9 — Installing Django and common Python/AI-ML packages..."
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

django-admin --version
print_success "Django installed: $(django-admin --version)"
print_success "All AI/ML Python packages installed."

# --------------------------------------------------------------------------- #
#  5. PostgreSQL 16 + pgAdmin 4
# --------------------------------------------------------------------------- #
print_step "5/9 — Installing PostgreSQL 16..."

# Add PostgreSQL official APT repo
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

echo "deb [signed-by=/etc/apt/trusted.gpg.d/postgresql.gpg] \
https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

apt-get update -y
apt-get install -y postgresql-16 postgresql-client-16 postgresql-contrib-16

# Start and enable PostgreSQL
systemctl enable postgresql
systemctl start postgresql

print_success "PostgreSQL 16 installed: $(psql --version)"

print_info "Installing pgAdmin 4..."
curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgadmin.gpg

echo "deb [signed-by=/etc/apt/trusted.gpg.d/pgadmin.gpg] \
https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" \
    > /etc/apt/sources.list.d/pgadmin4.list

apt-get update -y
apt-get install -y pgadmin4-desktop
print_success "pgAdmin 4 (Desktop) installed."

# --------------------------------------------------------------------------- #
#  6. Visual Studio Code
# --------------------------------------------------------------------------- #
print_step "6/9 — Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list

apt-get update -y
apt-get install -y code
print_success "VS Code installed: $(code --version | head -1)"

# Install useful VS Code extensions (runs as the logged-in user)
REAL_USER="${SUDO_USER:-$USER}"
print_info "Installing VS Code extensions for user: $REAL_USER"
sudo -u "$REAL_USER" code --install-extension ms-python.python            2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-python.pylance           2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-toolsai.jupyter          2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension ms-azuretools.vscode-docker 2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension github.copilot              2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension esbenp.prettier-vscode      2>/dev/null || true
sudo -u "$REAL_USER" code --install-extension mtxr.sqltools               2>/dev/null || true
print_success "VS Code extensions installed."

# --------------------------------------------------------------------------- #
#  7. Google Chrome
# --------------------------------------------------------------------------- #
print_step "7/9 — Installing Google Chrome..."
wget -q -O /tmp/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/google-chrome.deb
rm -f /tmp/google-chrome.deb
print_success "Google Chrome installed: $(google-chrome --version)"

# --------------------------------------------------------------------------- #
#  8. Microsoft Teams
# --------------------------------------------------------------------------- #
print_step "8/9 — Installing Microsoft Teams..."
wget -q -O /tmp/teams.deb \
    "https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.6.00.4472_amd64.deb" || \
wget -q -O /tmp/teams.deb \
    "https://go.microsoft.com/fwlink/p/?linkid=2112886&clcid=0x409&culture=en-us&country=us"

if apt-get install -y /tmp/teams.deb 2>/dev/null; then
    print_success "Microsoft Teams (classic) installed."
else
    # Fallback: Teams PWA via snap
    print_info "Trying Teams via snap..."
    snap install teams-for-linux --classic 2>/dev/null || \
    snap install teams-for-linux 2>/dev/null || true
    print_success "Microsoft Teams installed via snap."
fi
rm -f /tmp/teams.deb

# --------------------------------------------------------------------------- #
#  9. Postman
# --------------------------------------------------------------------------- #
print_step "9/9 — Installing Postman..."
snap install postman 2>/dev/null || {
    print_info "Snap failed, downloading Postman manually..."
    wget -q -O /tmp/postman.tar.gz \
        https://dl.pstmn.io/download/latest/linux64
    tar -xzf /tmp/postman.tar.gz -C /opt/
    ln -sf /opt/Postman/Postman /usr/local/bin/postman
    # Create desktop shortcut
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
echo -e "  ${GREEN}✔${NC} Git          : $(git --version)"
echo -e "  ${GREEN}✔${NC} Python       : $(python --version 2>&1)"
echo -e "  ${GREEN}✔${NC} pip          : $(pip3 --version 2>&1 | awk '{print $1,$2}')"
echo -e "  ${GREEN}✔${NC} Django       : $(django-admin --version 2>&1)"
echo -e "  ${GREEN}✔${NC} PostgreSQL   : $(psql --version 2>&1)"
echo -e "  ${GREEN}✔${NC} pgAdmin 4    : Installed (Desktop)"
echo -e "  ${GREEN}✔${NC} VS Code      : $(code --version 2>/dev/null | head -1)"
echo -e "  ${GREEN}✔${NC} Google Chrome: $(google-chrome --version 2>/dev/null)"
echo -e "  ${GREEN}✔${NC} MS Teams     : Installed"
echo -e "  ${GREEN}✔${NC} Postman      : Installed"
echo ""
echo -e "${YELLOW}Post-install tips:${NC}"
echo -e "  • PostgreSQL service : sudo systemctl status postgresql"
echo -e "  • pgAdmin 4          : Search 'pgAdmin 4' in Applications menu"
echo -e "  • Create a Django project: django-admin startproject myproject"
echo -e "  • Full log file      : $LOG_FILE"
echo ""
echo -e "${CYAN}Please REBOOT or re-login for all changes to take effect.${NC}"
echo -e "${CYAN}============================================================${NC}"
