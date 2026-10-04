#!/usr/bin/env bash
# ==============================================================================
#
#   ███████╗████████╗██████╗ ███████╗███╗   ██╗ ██████╗ ██╗  ██╗
#   ██╔════╝╚══██╔══╝██╔══██╗██╔════╝████╗  ██║██╔═══██╗╚██╗██╔╝
#   ███████╗   ██║   ██████╔╝█████╗  ██╔██╗ ██║██║   ██║ ╚███╔╝
#   ╚════██║   ██║   ██╔══██╗██╔══╝  ██║╚██╗██║██║   ██║ ██╔██╗
#   ███████║   ██║   ██║  ██║███████╗██║ ╚████║╚██████╔╝██╔╝ ██╗
#   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
#
#                        S T R E N O X   C L O U D
#                          Maintained by: kc5w
#
#   Proxmox VE Auto-Installer for Debian 13 (Trixie)
#   GitHub: github.com/kc5w
#
# ==============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

# ── Branding ──────────────────────────────────────────────────────────────────
BRAND="Strenox Cloud"
AUTHOR="kc5w"
LOG="/var/log/strenox-pve.log"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()   { echo -e "$(date '+%F %T') | $*" >> "$LOG"; }
info()  { echo -e "${CYAN}${BOLD}[ INFO ]${RESET} $*"; log "INFO  $*"; }
ok()    { echo -e "${GREEN}${BOLD}[  OK  ]${RESET} $*"; log "OK    $*"; }
warn()  { echo -e "${YELLOW}${BOLD}[ WARN ]${RESET} $*"; log "WARN  $*"; }
err()   { echo -e "${RED}${BOLD}[ FAIL ]${RESET} $*"; log "FAIL  $*"; }

step() {
  echo ""
  echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${WHITE}${BOLD}  ▸ $*${RESET}"
  echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

banner() {
  clear || true
  echo -e "${CYAN}${BOLD}"
  cat <<'EOF'
   ███████╗████████╗██████╗ ███████╗███╗   ██╗ ██████╗ ██╗  ██╗
   ██╔════╝╚══██╔══╝██╔══██╗██╔════╝████╗  ██║██╔═══██╗╚██╗██╔╝
   ███████╗   ██║   ██████╔╝█████╗  ██╔██╗ ██║██║   ██║ ╚███╔╝
   ╚════██║   ██║   ██╔══██╗██╔══╝  ██║╚██╗██║██║   ██║ ██╔██╗
   ███████║   ██║   ██║  ██║███████╗██║ ╚████║╚██████╔╝██╔╝ ██╗
   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
EOF
  echo -e "${RESET}"
  echo -e "           ${WHITE}${BOLD}★  S T R E N O X   C L O U D  ★${RESET}"
  echo -e "              ${DIM}Proxmox VE Installer${RESET}"
  echo -e "              ${YELLOW}Brought to you by ${BOLD}${AUTHOR}${RESET}"
  echo -e "         ${DIM}------------------------------------------------${RESET}"
  echo ""
}

# ── Root check ────────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  err "This script must be run as ${BOLD}root${RESET}${RED}. Try: sudo bash pve.sh"
  exit 1
fi

touch "$LOG" 2>/dev/null || true

banner

# ── Confirm ───────────────────────────────────────────────────────────────────
info "This will install ${BOLD}Proxmox VE${RESET} on Debian 13 (Trixie)."
info "The system will ${BOLD}REBOOT${RESET} at the end."
echo ""
read -rp "$(echo -e "${YELLOW}${BOLD}▸ Continue? [y/N]: ${RESET}")" CONFIRM
[[ "${CONFIRM,,}" == "y" || "${CONFIRM,,}" == "yes" ]] || { warn "Aborted by user."; exit 0; }

# ── Step 1: Hostname ──────────────────────────────────────────────────────────
step "1/7  Setting hostname → pve"
hostnamectl set-hostname pve
ok "Hostname set to ${BOLD}pve${RESET}"

# ── Step 2: Remove enterprise repo ────────────────────────────────────────────
step "2/7  Removing enterprise repository"
rm -f /etc/apt/sources.list.d/pve-enterprise.list
ok "Enterprise repo removed"

# ── Step 3: Add no-subscription repo ──────────────────────────────────────────
step "3/7  Adding Proxmox no-subscription repository (Trixie)"
cat > /etc/apt/sources.list.d/pve-install-repo.list <<'EOF'
deb http://download.proxmox.com/debian/pve trixie pve-no-subscription
EOF
ok "Repo file created: /etc/apt/sources.list.d/pve-install-repo.list"

# ── Step 4: Import GPG key ────────────────────────────────────────────────────
step "4/7  Importing Proxmox release GPG key"
wget -q https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg \
  -O /etc/apt/trusted.gpg.d/proxmox-release-trixie.gpg
ok "GPG key installed"

# ── Step 5: Update + install core packages ────────────────────────────────────
step "5/7  Updating packages & installing Proxmox VE"
info "Running apt update..."
apt update -y
info "Preseeding postfix → Local only"
echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections
echo "postfix postfix/mailname string pve.strenox.cloud" | debconf-set-selections
info "Installing proxmox-ve, postfix, open-iscsi, chrony ..."
DEBIAN_FRONTEND=noninteractive apt install -y \
  proxmox-ve postfix open-iscsi chrony
ok "Proxmox VE core installed"

# ── Step 6: Kernel ────────────────────────────────────────────────────────────
step "6/7  Installing Proxmox default kernel"
DEBIAN_FRONTEND=noninteractive apt install -y proxmox-default-kernel
info "Updating GRUB..."
update-grub
ok "Kernel installed & GRUB updated"

# ── Step 7: Reboot ────────────────────────────────────────────────────────────
step "7/7  Finalizing"
echo ""
ok "🎉  ${BOLD}${BRAND}${RESET}${GREEN} — Proxmox VE installation complete!${RESET}"
echo ""
echo -e "${CYAN}   Access the web UI after reboot at:${RESET}"
echo -e "   ${BOLD}${WHITE}https://<your-ip>:8006${RESET}"
echo ""
echo -e "${DIM}   Log saved to: ${LOG}${RESET}"
echo -e "${DIM}   Script by ${AUTHOR} — ${BRAND}${RESET}"
echo ""

read -rp "$(echo -e "${YELLOW}${BOLD}▸ Reboot now? [Y/n]: ${RESET}")" RB
if [[ -z "${RB}" || "${RB,,}" == "y" || "${RB,,}" == "yes" ]]; then
  info "Rebooting in 5 seconds... (Ctrl+C to cancel)"
  sleep 5
  reboot
else
  warn "Reboot skipped. Please reboot manually to boot into the Proxmox kernel."
fi
