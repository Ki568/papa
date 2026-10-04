#!/bin/bash

# ============================================================
#              STRenox Cloud • Proxmox Installer
# ============================================================

# ---------- Colors ----------
PURPLE='\033[38;5;141m'
CYAN='\033[38;5;81m'
GREEN='\033[38;5;82m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;220m'
WHITE='\033[1;37m'
GRAY='\033[38;5;245m'
RESET='\033[0m'

# ---------- UI Functions ----------

line() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

type_text() {
    text="$1"
    delay="${2:-0.015}"

    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

ok() {
    echo -e "  ${GREEN}✔${RESET} $1"
}

info() {
    echo -e "  ${CYAN}➜${RESET} $1"
}

warn() {
    echo -e "  ${YELLOW}⚠${RESET} $1"
}

fail() {
    echo -e "  ${RED}✘${RESET} $1"
}

step() {
    echo
    echo -e "${WHITE}[$1]${RESET} ${CYAN}$2${RESET}"
    line
}

# ============================================================
#                    STRenox CLOUD BANNER
# ============================================================

clear

echo -e "${PURPLE}"

cat <<'EOF'

   _____ _                               _____ _                 _ 
  / ____| |                             / ____| |               | |
 | (___ | |_ _ __ ___ _ __   _____  __ | |    | | ___  _   _  __| |
  \___ \| __| '__/ _ \ '_ \ / _ \ \/ / | |    | |/ _ \| | | |/ _` |
  ____) | |_| | |  __/ | | | (_) >  <  | |____| | (_) | |_| | (_| |
 |_____/ \__|_|  \___|_| |_|\___/_/\_\  \_____|_|\___/ \__,_|\__,_|
                                                                   
                                                                   

EOF

echo -e "${RESET}"

echo -e "${WHITE}                 Proxmox VE Installation System${RESET}"
echo -e "${GRAY}                    Powered by Strenox Cloud${RESET}"

echo
line

type_text "  Initializing Strenox Cloud installer..." 0.025
sleep 0.5

# ============================================================
#                    SYSTEM CHECKS
# ============================================================

step "01" "SYSTEM CHECKS"

if [ "$EUID" -ne 0 ]; then
    fail "This installer must be run as root."
    echo
    exit 1
fi

ok "Root access detected"

if ping -c 1 -W 2 download.proxmox.com >/dev/null 2>&1; then
    ok "Internet connection detected"
else
    fail "Internet connection unavailable"
    echo
    exit 1
fi

if command -v hostnamectl >/dev/null 2>&1; then
    ok "System utilities available"
else
    fail "Required system utilities unavailable"
    echo
    exit 1
fi

sleep 1

# ============================================================
#                    HOSTNAME
# ============================================================

step "02" "CONFIGURING HOSTNAME"

info "Setting hostname to pve..."

hostnamectl set-hostname pve

ok "Hostname configured"

sleep 0.5

# ============================================================
#                    REPOSITORY
# ============================================================

step "03" "CONFIGURING PROXMOX REPOSITORY"

info "Removing enterprise repository..."

rm -f /etc/apt/sources.list.d/pve-enterprise.list

ok "Enterprise repository removed"

info "Creating Proxmox no-subscription repository..."

cat > /etc/apt/sources.list.d/pve-install-repo.list <<'EOF'
deb http://download.proxmox.com/debian/pve trixie pve-no-subscription
EOF

ok "Proxmox repository configured"

# ============================================================
#                    PROXMOX GPG KEY
# ============================================================

step "04" "INSTALLING PROXMOX REPOSITORY KEY"

info "Downloading Proxmox release key..."

wget https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg \
-O /etc/apt/trusted.gpg.d/proxmox-release-trixie.gpg

ok "Proxmox repository key installed"

# ============================================================
#                    APT UPDATE
# ============================================================

step "05" "UPDATING PACKAGE DATABASE"

info "Running apt update..."

apt update

ok "Package database updated"

# ============================================================
#                    PROXMOX INSTALL
# ============================================================

step "06" "INSTALLING PROXMOX VE"

echo
echo -e "${YELLOW}  ⚠ POSTFIX CONFIGURATION REQUIRED${RESET}"
echo
echo -e "${WHITE}  When the Postfix configuration screen appears:${RESET}"
echo
echo -e "  ${CYAN}→${RESET} Select ${WHITE}Local only${RESET}"
echo -e "  ${CYAN}→${RESET} Press ${WHITE}ENTER${RESET}"
echo
echo -e "${GRAY}  The installer will continue automatically afterwards.${RESET}"
echo

read -p "  Press ENTER when you are ready to start installation..."

echo

apt install -y proxmox-ve postfix open-iscsi chrony

ok "Proxmox VE packages installed"

# ============================================================
#                    PROXMOX KERNEL
# ============================================================

step "07" "INSTALLING PROXMOX DEFAULT KERNEL"

info "Installing Proxmox default kernel..."

apt install -y proxmox-default-kernel

ok "Proxmox kernel installed"

# ============================================================
#                    GRUB
# ============================================================

step "08" "UPDATING BOOTLOADER"

info "Updating GRUB configuration..."

update-grub

ok "GRUB configuration updated"

# ============================================================
#                    COMPLETE
# ============================================================

echo
line

echo
echo -e "${GREEN}"

cat <<'EOF'

   ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ███████╗████████╗███████╗
  ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██╔════╝╚══██╔══╝██╔════╝
  ██║     ██║   ██║██╔████╔██║██████╔╝██║     █████╗     ██║   █████╗
  ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝     ██║   ██╔══╝
  ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗███████╗   ██║   ███████╗
   ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝   ╚══════╝

EOF

echo -e "${RESET}"

echo -e "${GREEN}  ✔ Proxmox VE installation completed successfully!${RESET}"
echo

echo -e "${CYAN}  Hostname:${RESET}     pve"
echo -e "${CYAN}  Repository:${RESET}   Proxmox VE No-Subscription"
echo -e "${CYAN}  Kernel:${RESET}       Proxmox Default Kernel"
echo -e "${CYAN}  Postfix:${RESET}      Local only"
echo

line

echo
echo -e "${YELLOW}  ⚠ A system reboot is required.${RESET}"
echo

for i in 5 4 3 2 1; do
    echo -ne "\r  Rebooting in ${WHITE}${i}${RESET}..."
    sleep 1
done

echo
echo
echo -e "${PURPLE}  Strenox Cloud • Powering your infrastructure.${RESET}"
echo

reboot
