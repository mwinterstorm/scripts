#!/bin/bash
# Various Matrix Ansible Commands

#!/bin/bash

GREEN="\033[1;32m"
NOCOLOR="\033[0m"
YELLOW="\033[1;33m"; RED="\033[0;31m"; ENDCOLOR="\033[0m"


echo Matrix updates by Mark
echo
df -hT -t ext4
echo
echo Select Action:
echo 1. Clean Database
echo 2. Clean Other - prune docker etc
echo 3. Upgrade to latest
read -p 'Select Number: ' action

if [[ $action = 'y' ]]
then
    echo cleaning...

    # # if not root, run as root
    # if (( $EUID != 0 )); then
    #     sudo bash $HOME/upgrade.sh
    #     exit
    # fi

    # echo

    # echo -e "step 1: ${GREEN}delete downloaded packages (.deb) already installed (and no longer needed)${NOCOLOR}"
    # apt-get clean

    # echo

    # echo -e "step 2: ${GREEN}remove all stored archives in your cache for packages that can not be downloaded anymore (thus packages that are no longer in the repository or that have a newer version in the repository)${NOCOLOR}"
    # apt-get autoclean

    # echo

    # echo -e "step 3: ${GREEN}remove unnecessary packages (After uninstalling an app there could be packages you don't need anymore)${NOCOLOR}"
    # apt-get autoremove

    # echo

    # echo -e "step 4: ${GREEN}rerun clean${NOCOLOR}"
    # apt-get clean

    # echo


    # echo -e $YELLOW"Those packages were uninstalled without --purge:"$ENDCOLOR
    # echo $OLDCONF
    # for PKGNAME in $OLDCONF ; do  # a better way to handle errors
    #     echo -e $YELLOW"Purge package $PKGNAME"
    #     apt-cache show "$PKGNAME"|grep Description: -A3
    #     apt-get -y purge "$PKGNAME"
    # done

    # echo

    # echo -e $YELLOW"Removing old kernels..."$ENDCOLOR
    # echo current kernel you are using:
    # uname -a
    # apt purge $OLDKERNELS

    # echo

    # echo -e $YELLOW"Emptying trashes..."$ENDCOLOR
    # rm -rf /home/*/.local/share/Trash/*/** &> /dev/null
    # rm -rf /root/.local/share/Trash/*/** &> /dev/null

    # echo

    # echo -e "step 5: ${GREEN}Remove the oldest archived journal files until the disk space they use falls below the specified size${NOCOLOR}"
    # journalctl --vacuum-size 10M

    # echo

    # echo Does this VM have docker? and do you want to purge docker?

    # read -p '[y/n]: ' varok

    # if [[ $varok = 'y' ]]
    # then

    # echo -e "step 6: ${GREEN}purging docker${NOCOLOR}"
    # docker container prune -f && docker image prune -f

    # echo
    # fi

    # echo Remove old revisions of snaps?

    # read -p '[y/n]: ' varsnap

    # if [[ $varsnap = 'y' ]]
    # then

    # set -eu
    # snap list --all | awk '/disabled/{print $1, $3}' |
    #     while read snapname revision; do
    #         snap remove "$snapname" --revision="$revision"
    #     done

    fi

echo
echo Cleaning complete
echo
df -hT -t ext4

fi