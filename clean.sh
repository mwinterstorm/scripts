#!/bin/bash
ST_CLEAN_DAYS="${ST_CLEAN_DAYS:-7}"
# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS

TRASH_PATHS="${TRASH_PATHS:-/home/*/.local/share/Trash/*/** /root/.local/share/Trash/*/**}"
KERNEL_KEEP="${KERNEL_KEEP:-1}"

VACUUM_SIZE="${VACUUM_SIZE:-10M}"
DISK_TYPE="${DISK_TYPE:-ext4}"

GREEN="\033[1;32m"
NOCOLOR="\033[0m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
DRYRUN=false
LOGFILE="/var/log/clean-script.log"
NUCLEAR=false

for arg in "$@"; do
    case $arg in
        --dry-run|-n)
            DRYRUN=true
            ;;
        --logfile=*|-l=*)
            LOGFILE="${arg#*=}"
            ;;
        --clear-log|-c)
            echo "Clearing log file: $LOGFILE"
            > "$LOGFILE"
            exit 0
            ;;
        --help|-h)
            echo -e "${GREEN}Usage: clean.sh [OPTIONS]${NOCOLOR}"
            echo ""
            echo -e "${YELLOW}Options:${NOCOLOR}"
            echo -e "  ${GREEN}--dry-run, -n       ${NOCOLOR}Perform a trial run with no changes made"
            echo -e "  ${GREEN}--logfile=PATH, -l=PATH ${NOCOLOR}Specify a custom path for the log file"
            echo -e "  ${GREEN}--clear-log, -c     ${NOCOLOR}Clear the log file and exit"
            echo -e "  ${GREEN}--help, -h          ${NOCOLOR}Show this help message and exit"
            echo -e "  ${GREEN}--nuclear          ${NOCOLOR}EXTREME cleanup: remove locales, man pages, and aggressively purge journals"
            exit 0
            ;;
        --nuclear)
            NUCLEAR=true
            ;;
    esac
done

DISK_MOUNT="${DISK_MOUNT:-/}"
START_USAGE=$(df --output=used -k "$DISK_MOUNT" | tail -1)

echo "==== Cleanup started at $(date) ====" > "$LOGFILE"
echo "Dry run mode: $DRYRUN" >> "$LOGFILE"
echo "Vacuum size: $VACUUM_SIZE" >> "$LOGFILE"
echo "Disk type: $DISK_TYPE" >> "$LOGFILE"
echo "Trash paths: $TRASH_PATHS" >> "$LOGFILE"
echo "Kernel versions to keep: $KERNEL_KEEP" >> "$LOGFILE"

OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
KERNELS=$(dpkg -l | awk '/^ii/ && $2 ~ /^linux-image-[0-9]/ { print $2 }' | sort -V)
CURRENT_KERNEL=$(uname -r)
OLDKERNELS=$(echo "$KERNELS" | grep -v "$CURRENT_KERNEL" | head -n -"$KERNEL_KEEP")

echo Cleaning script by Mark
echo
df -hT -t "$DISK_TYPE"
echo
echo Proceed with clean?
read -p '[y/n]: ' clean

if [[ $clean = 'y' ]]
then
    echo cleaning...

    # if not root, run as root
    if (( $EUID != 0 )); then
        echo "Please run this script as root."
        exit 1
    fi

    echo

    echo -e "step 1: ${GREEN}delete downloaded packages (.deb) already installed (and no longer needed)${NOCOLOR}"
    echo "Running: apt-get clean" | tee -a "$LOGFILE"
    $DRYRUN || apt-get clean >> "$LOGFILE" 2>&1

    echo

    echo -e "step 2: ${GREEN}remove all stored archives in your cache for packages that can not be downloaded anymore (thus packages that are no longer in the repository or that have a newer version in the repository)${NOCOLOR}"
    echo "Running: apt-get autoclean" | tee -a "$LOGFILE"
    $DRYRUN || apt-get autoclean >> "$LOGFILE" 2>&1

    echo

    echo -e "step 3: ${GREEN}remove unnecessary packages (After uninstalling an app there could be packages you don't need anymore)${NOCOLOR}"
    echo "Running: apt-get autoremove" | tee -a "$LOGFILE"
    $DRYRUN || apt-get autoremove >> "$LOGFILE" 2>&1

    echo
    if command -v deborphan &> /dev/null; then
        echo -e "${YELLOW}Removing orphaned packages${NOCOLOR}" | tee -a "$LOGFILE"
        deborphan | tee -a "$LOGFILE"
        $DRYRUN || deborphan | xargs -r apt-get -y purge >> "$LOGFILE" 2>&1
    else
        echo "deborphan not installed." | tee -a "$LOGFILE"
        read -p "Do you want to install deborphan? [y/n]: " install_deborphan
        if [[ $install_deborphan == "y" ]]; then
            echo "Installing deborphan..." | tee -a "$LOGFILE"
            $DRYRUN || apt-get update >> "$LOGFILE" 2>&1
            $DRYRUN || apt-get install -y deborphan >> "$LOGFILE" 2>&1
        else
            echo "Skipping orphaned package cleanup." | tee -a "$LOGFILE"
        fi
    fi

    echo

    echo -e "step 4: ${GREEN}rerun clean${NOCOLOR}"
    echo "Running: apt-get clean" | tee -a "$LOGFILE"
    $DRYRUN || apt-get clean >> "$LOGFILE" 2>&1

    echo

    echo -e $YELLOW"Those packages were uninstalled without --purge:"$ENDCOLOR
    echo $OLDCONF
    for PKGNAME in $OLDCONF ; do  # a better way to handle errors
        echo -e $YELLOW"Purge package $PKGNAME"
        apt-cache show "$PKGNAME"|grep Description: -A3
        echo "Running: apt-get -y purge \"$PKGNAME\"" | tee -a "$LOGFILE"
        $DRYRUN || apt-get -y purge "$PKGNAME" >> "$LOGFILE" 2>&1
    done

    echo

    echo -e $YELLOW"Removing old kernels..."$ENDCOLOR
    echo current kernel you are using:
    uname -a
    echo "Running: apt purge $OLDKERNELS" | tee -a "$LOGFILE"
    $DRYRUN || apt purge $OLDKERNELS >> "$LOGFILE" 2>&1

    echo

    echo -e $YELLOW"Emptying trashes..."$ENDCOLOR
    for path in $TRASH_PATHS; do
        echo "Running: rm -rf $path" | tee -a "$LOGFILE"
        $DRYRUN || rm -rf $path >> "$LOGFILE" 2>&1
    done

    echo
    echo -e "${YELLOW}Cleaning /var/cache (non-APT)${NOCOLOR}" | tee -a "$LOGFILE"
    $DRYRUN || find /var/cache -type f -exec rm -f {} + >> "$LOGFILE" 2>&1

    echo
    echo -e "${YELLOW}Cleaning /tmp and /var/tmp${NOCOLOR}" | tee -a "$LOGFILE"
    $DRYRUN || find /tmp /var/tmp -mindepth 1 -delete >> "$LOGFILE" 2>&1

    echo
    echo -e "${YELLOW}Removing core dumps${NOCOLOR}" | tee -a "$LOGFILE"
    $DRYRUN || find / -type f -name 'core' -exec rm -f {} + >> "$LOGFILE" 2>&1

    echo
    echo -e "${YELLOW}Top 10 largest files${NOCOLOR}" | tee -a "$LOGFILE"
    find / -type f -size +100M -exec du -h {} + 2>/dev/null | sort -hr | head -n 10 | tee -a "$LOGFILE"

    echo
    echo -e "${YELLOW}Cleaning rotated and uncompressed logs${NOCOLOR}" | tee -a "$LOGFILE"
    $DRYRUN || find /var/log -type f \( -name "*.log" -o -name "*.gz" -o -name "*.1" \) -delete >> "$LOGFILE" 2>&1

    echo
    echo -e "${YELLOW}Cleaning user caches${NOCOLOR}" | tee -a "$LOGFILE"
    $DRYRUN || rm -rf /home/*/.cache /root/.cache /home/*/.npm /root/.npm >> "$LOGFILE" 2>&1

    echo
    if command -v syncthing &> /dev/null; then
        echo -e "${YELLOW}Cleaning Syncthing versioned files older than ${ST_CLEAN_DAYS} days${NOCOLOR}" | tee -a "$LOGFILE"
        $DRYRUN || find /root/Calibre/.stversions/ -type f -mtime +$ST_CLEAN_DAYS -exec rm -f {} + >> "$LOGFILE" 2>&1
    else
        echo "Syncthing not installed. Skipping Syncthing cleanup." | tee -a "$LOGFILE"
    fi

    if command -v docker &> /dev/null; then
        echo Does this VM have docker? and do you want to purge docker?
        read -p '[y/n]: ' varok
        if [[ $varok = 'y' ]]; then
            echo -e "step 6: ${GREEN}purging docker${NOCOLOR}"
            echo "Running: docker container prune -f" | tee -a "$LOGFILE"
            $DRYRUN || docker container prune -f >> "$LOGFILE" 2>&1
            echo "Running: docker image prune -f" | tee -a "$LOGFILE"
            $DRYRUN || docker image prune -f >> "$LOGFILE" 2>&1
            echo
        fi
    else
        echo "Docker not installed. Skipping Docker cleanup."
    fi

    echo Remove old revisions of snaps?

    if command -v snap &> /dev/null; then
        read -p '[y/n]: ' varsnap
        if [[ $varsnap = 'y' ]]; then
            set -eu
            snap list --all | awk '/disabled/{print $1, $3}' |
                while read snapname revision; do
                    echo "Running: snap remove \"$snapname\" --revision=\"$revision\"" | tee -a "$LOGFILE"
                    $DRYRUN || snap remove "$snapname" --revision="$revision" >> "$LOGFILE" 2>&1
                done
        fi
    else
        echo "Snap not installed. Skipping snap cleanup."
    fi

    echo
    echo -e "${YELLOW}Cleaning Snap mounts and cached snaps${NOCOLOR}" | tee -a "$LOGFILE"
    $DRYRUN || umount /snap/* 2>/dev/null
    $DRYRUN || rm -rf /var/lib/snapd/snaps/*.snap >> "$LOGFILE" 2>&1

    echo

    if [[ "$NUCLEAR" == true ]]; then
        echo
        echo -e "${RED}*** WARNING: NUCLEAR MODE ACTIVE ***${NOCOLOR}" | tee -a "$LOGFILE"

        echo -e "${YELLOW}Removing man pages${NOCOLOR}" | tee -a "$LOGFILE"
        $DRYRUN || rm -rf /usr/share/man/* >> "$LOGFILE" 2>&1

        echo -e "${YELLOW}Aggressively vacuuming journal logs${NOCOLOR}" | tee -a "$LOGFILE"
        $DRYRUN || journalctl --vacuum-size=1M >> "$LOGFILE" 2>&1

        if command -v localepurge &> /dev/null; then
            echo -e "${YELLOW}Running localepurge${NOCOLOR}" | tee -a "$LOGFILE"
            $DRYRUN || localepurge >> "$LOGFILE" 2>&1
        else
            echo "localepurge not installed." | tee -a "$LOGFILE"
            read -p "Install localepurge? [y/n]: " install_lp
            if [[ "$install_lp" == "y" ]]; then
                echo "Installing localepurge..." | tee -a "$LOGFILE"
                $DRYRUN || echo 'localepurge	localepurge/nopurge	multiselect en, en_NZ.UTF-8' | debconf-set-selections
                $DRYRUN || DEBIAN_FRONTEND=noninteractive apt-get install -y localepurge >> "$LOGFILE" 2>&1
                echo "Running localepurge..." | tee -a "$LOGFILE"
                $DRYRUN || localepurge >> "$LOGFILE" 2>&1
            else
                echo "Skipping locale cleanup." | tee -a "$LOGFILE"
            fi
        fi
    fi

    echo Cleaning complete
    echo

    END_USAGE=$(df --output=used -k "$DISK_MOUNT" | tail -1)
    START_VAL=$(echo "$START_USAGE" | awk '{print $1}')
    END_VAL=$(echo "$END_USAGE" | awk '{print $1}')
    if [[ "$START_VAL" =~ ^[0-9]+$ && "$END_VAL" =~ ^[0-9]+$ ]]; then
        FREED_KB=$((START_VAL - END_VAL))
        FREED_MB=$((FREED_KB / 1024))
        if command -v numfmt >/dev/null; then
            FREED_HUMAN=$(numfmt --to=iec $((FREED_MB * 1024 * 1024)))
            START_HUMAN=$(numfmt --to=iec $((START_VAL * 1024)))
            END_HUMAN=$(numfmt --to=iec $((END_VAL * 1024)))
        else
            FREED_HUMAN="${FREED_MB}MB"
            START_HUMAN="${START_VAL}KB"
            END_HUMAN="${END_VAL}KB"
        fi
        PERCENT=$(awk "BEGIN { pc=100*${FREED_KB}/${START_VAL}; print int(pc) }")
    else
        FREED_MB=0
        FREED_HUMAN="N/A"
        START_HUMAN="N/A"
        END_HUMAN="N/A"
        PERCENT="N/A"
    fi
    df -h "$DISK_MOUNT" | tee -a "$LOGFILE"
    $DRYRUN && echo "Dry run mode: no changes were actually made." | tee -a "$LOGFILE"

    echo
    echo -e "${GREEN}Summary Report:${NOCOLOR}" | tee -a "$LOGFILE"
    echo -e "Start Usage: $START_VAL KB ($START_HUMAN)" | tee -a "$LOGFILE"
    echo -e "End Usage:   $END_VAL KB ($END_HUMAN)" | tee -a "$LOGFILE"
    echo -e "Freed Space: ${FREED_MB} MB (${FREED_HUMAN})" | tee -a "$LOGFILE"
    echo -e "Total Used:  $END_VAL KB ($END_HUMAN)" | tee -a "$LOGFILE"
    echo -e "Percent Freed: ${PERCENT}%" | tee -a "$LOGFILE"
    echo -e "Log File:     $LOGFILE" | tee -a "$LOGFILE"

fi