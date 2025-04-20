#!/bin/bash

LOGFILE="/var/log/update-script.log"
echo "==== Update started at $(date) ====" > "$LOGFILE"

GREEN="\033[1;32m"
NOCOLOR="\033[0m"

# if not root, run as root
if (( $EUID != 0 )); then
    echo "Re-running as root..." | tee -a "$LOGFILE"
    exec sudo bash "$0"
fi

echo

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

echo

echo Ok to proceed?

read -p '[y/n]: ' varok

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

if [ -f /var/run/reboot-required ]; then
    echo | tee -a "$LOGFILE"
    echo -e "${GREEN}System update complete.${NOCOLOR}" | tee -a "$LOGFILE"
    echo "Uptime: $(uptime -p)" | tee -a "$LOGFILE"
    echo "Kernel: $(uname -r)" | tee -a "$LOGFILE"
    echo "Disk Usage:" | tee -a "$LOGFILE"
    df -h / | tee -a "$LOGFILE"
    echo "Log File: $LOGFILE" | tee -a "$LOGFILE"
    read -p "Reboot now? [y/n]: " rebootnow
    [[ $rebootnow == "y" ]] && reboot
fi
fi