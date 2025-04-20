#!/bin/bash
# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS

GREEN="\033[1;32m"
NOCOLOR="\033[0m"
OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)
YELLOW="\033[1;33m"; RED="\033[0;31m"; ENDCOLOR="\033[0m"


echo Cleaning script by Mark
echo
df -hT -t ext4
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
    apt-get clean

    echo

    echo -e "step 2: ${GREEN}remove all stored archives in your cache for packages that can not be downloaded anymore (thus packages that are no longer in the repository or that have a newer version in the repository)${NOCOLOR}"
    apt-get autoclean

    echo

    echo -e "step 3: ${GREEN}remove unnecessary packages (After uninstalling an app there could be packages you don't need anymore)${NOCOLOR}"
    apt-get autoremove

    echo

    echo -e "step 4: ${GREEN}rerun clean${NOCOLOR}"
    apt-get clean

    echo


    echo -e $YELLOW"Those packages were uninstalled without --purge:"$ENDCOLOR
    echo $OLDCONF
    for PKGNAME in $OLDCONF ; do  # a better way to handle errors
        echo -e $YELLOW"Purge package $PKGNAME"
        apt-cache show "$PKGNAME"|grep Description: -A3
        apt-get -y purge "$PKGNAME"
    done

    echo

    echo -e $YELLOW"Removing old kernels..."$ENDCOLOR
    echo current kernel you are using:
    uname -a
    apt purge $OLDKERNELS

    echo

    echo -e $YELLOW"Emptying trashes..."$ENDCOLOR
    rm -rf /home/*/.local/share/Trash/*/** &> /dev/null
    rm -rf /root/.local/share/Trash/*/** &> /dev/null

    echo

    echo -e "step 5: ${GREEN}Remove the oldest archived journal files until the disk space they use falls below the specified size${NOCOLOR}"
    journalctl --vacuum-size 10M

    echo

    if command -v docker &> /dev/null; then
        echo Does this VM have docker? and do you want to purge docker?
        read -p '[y/n]: ' varok
        if [[ $varok = 'y' ]]; then
            echo -e "step 6: ${GREEN}purging docker${NOCOLOR}"
            docker container prune -f && docker image prune -f
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
                    snap remove "$snapname" --revision="$revision"
                done
        fi
    else
        echo "Snap not installed. Skipping snap cleanup."
    fi

    echo
    echo Cleaning complete
    echo
    df -hT -t ext4

fi