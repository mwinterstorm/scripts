#!/bin/bash

LOGFILE="/var/log/update-script.log"
SILENT=false
FORCE=false
for arg in "$@"; do
  case $arg in
    --silent|-s) SILENT=true ;;
    --force|-f) FORCE=true ;;
    --help|-h)
      echo -e "${GREEN}Usage: $0 [OPTIONS]${NOCOLOR}"
      echo ""
      echo "Options:"
      echo "  --silent, -s       Suppress prompts and only log output"
      echo "  --force, -f        Proceed without asking for confirmation"
      echo "  --help, -h         Show this help message"
      exit 0
      ;;
  esac
done

echo "==== Update started at $(date) ====" > "$LOGFILE"

GREEN="\033[1;32m"
NOCOLOR="\033[0m"

# if not root, run as root
if (( $EUID != 0 )); then
    echo "Re-running as root..." | tee -a "$LOGFILE"
    exec sudo bash "$0"
fi

echo

UPDATE_START=$(date +%s)

echo -e "step 1: ${GREEN}pre-configuring packages${NOCOLOR}" | tee -a "$LOGFILE"
dpkg --configure -a >> "$LOGFILE" 2>&1

echo

echo -e "step 2: ${GREEN}fix and attempt to correct a system with broken dependencies${NOCOLOR}" | tee -a "$LOGFILE"
apt-get install -f -y >> "$LOGFILE" 2>&1

echo

echo -e "step 3: ${GREEN}update apt cache${NOCOLOR}" | tee -a "$LOGFILE"
apt-get update >> "$LOGFILE" 2>&1

echo

echo -e "step 4: ${GREEN}check update packages${NOCOLOR}" | tee -a "$LOGFILE"
apt list --upgradable | tee -a "$LOGFILE"

echo -e "${GREEN}Upgrade candidates listed above.${NOCOLOR}" | tee -a "$LOGFILE"
if [[ "$FORCE" == true ]]; then
  varok="y"
  echo "Proceeding with upgrade (forced)." | tee -a "$LOGFILE"
else
  echo "Ok to proceed with full upgrade?" | tee -a "$LOGFILE"
  read -p '[y/n]: ' varok
fi

if [[ $varok = 'y' ]]
then

echo -e "step 5: ${GREEN}upgrade packages${NOCOLOR}" | tee -a "$LOGFILE"
apt-get upgrade -y >> "$LOGFILE" 2>&1

echo

echo -e "step 6: ${GREEN}distribution upgrade${NOCOLOR}" | tee -a "$LOGFILE"
apt-get dist-upgrade -y >> "$LOGFILE" 2>&1

echo

echo -e "step 7: ${GREEN}remove unused packages${NOCOLOR}" | tee -a "$LOGFILE"
apt-get --purge autoremove -y >> "$LOGFILE" 2>&1

echo

echo -e "step 8: ${GREEN}clean up${NOCOLOR}" | tee -a "$LOGFILE"
apt-get autoclean -y >> "$LOGFILE" 2>&1

echo
fi

UPDATE_END=$(date +%s)
DURATION=$((UPDATE_END - UPDATE_START))
DURATION_HM=$(printf '%02d:%02d' $((DURATION/60)) $((DURATION%60)))

echo | tee -a "$LOGFILE"
echo -e "${GREEN}System update complete.${NOCOLOR}" | tee -a "$LOGFILE"
echo "Duration: $DURATION seconds ($DURATION_HM)" | tee -a "$LOGFILE"
echo "Uptime: $(uptime -p)" | tee -a "$LOGFILE"
echo "Kernel: $(uname -r)" | tee -a "$LOGFILE"
echo "Disk Usage:" | tee -a "$LOGFILE"
df -h / | tee -a "$LOGFILE"
echo "Log File: $LOGFILE" | tee -a "$LOGFILE"

if [ -f /var/run/reboot-required ]; then
    echo
    read -p "Reboot now? [y/n]: " rebootnow
    [[ $rebootnow == "y" ]] && reboot
fi