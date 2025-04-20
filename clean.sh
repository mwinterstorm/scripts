#!/bin/bash
# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS

VACUUM_SIZE="${VACUUM_SIZE:-10M}"
DISK_TYPE="${DISK_TYPE:-ext4}"

GREEN="\033[1;32m"
NOCOLOR="\033[0m"
YELLOW="\033[1;33m"
DRYRUN=false
LOGFILE="/var/log/clean-script.log"

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
            exit 0
            ;;
    esac
done

echo "==== Cleanup started at $(date) ====" > "$LOGFILE"
echo "Dry run mode: $DRYRUN" >> "$LOGFILE"
echo "Vacuum size: $VACUUM_SIZE" >> "$LOGFILE"
echo "Disk type: $DISK_TYPE" >> "$LOGFILE"

OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)
RED="\033[0;31m"; ENDCOLOR="\033[0m"

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
    echo "Running: rm -rf /home/*/.local/share/Trash/*/**" | tee -a "$LOGFILE"
    $DRYRUN || rm -rf /home/*/.local/share/Trash/*/** >> "$LOGFILE" 2>&1
    echo "Running: rm -rf /root/.local/share/Trash/*/**" | tee -a "$LOGFILE"
    $DRYRUN || rm -rf /root/.local/share/Trash/*/** >> "$LOGFILE" 2>&1

    echo

    echo -e "step 5: ${GREEN}Remove the oldest archived journal files until the disk space they use falls below the specified size${NOCOLOR}"
    echo "Running: journalctl --vacuum-size $VACUUM_SIZE" | tee -a "$LOGFILE"
    $DRYRUN || journalctl --vacuum-size "$VACUUM_SIZE" >> "$LOGFILE" 2>&1

    echo

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
    echo Cleaning complete
    echo
    df -hT -t "$DISK_TYPE" | tee -a "$LOGFILE"
    $DRYRUN && echo "Dry run mode: no changes were actually made." | tee -a "$LOGFILE"

fi