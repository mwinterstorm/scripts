#!/bin/bash
# Various Matrix Ansible Commands

#!/bin/bash

GREEN="\033[1;32m"
NOCOLOR="\033[0m"
YELLOW="\033[1;33m" 
RED="\033[0;31m" 
ENDCOLOR="\033[0m"


echo Matrix updates by Mark
echo
scho Disk report:
df -hT -t ext4
echo
echo Select Action:

echo 0. Check system status
echo 1. Clean Database
echo 2. Clean Other - prune docker etc and run clean.sh
echo 3. Upgrade to latest

read -p 'Select Number: ' action

if [[ $action = '1' ]]
then
    echo -e "${GREEN}cleaning database...${NOCOLOR}"

    echo

    cd ~/matrix-docker-ansible-deploy/
    ansible-playbook -i inventory/hosts setup.yml --tags=run-postgres-vacuum --ask-pass

    echo
    echo -e "${GREEN}...cleaning database complete${NOCOLOR}"
    echo
    
    cd ~

    df -hT -t ext4

elif [[ $action = '2' ]]
then 

    echo -e "${GREEN} cleaning system... ${NOCOLOR}"
    echo
    echo -e "${YELLOW} ... running docker prune ... ${NOCOLOR}"
    echo

    cd ~/matrix-docker-ansible-deploy/
    ansible-playbook -i inventory/hosts setup.yml --tags=run-docker-prune --ask-pass

    echo 

    echo -e "${YELLOW} ... docker prune run, running cleaning script ... ${NOCOLOR}"

    echo 

    cd ~/scripts
    bash clean.sh

    echo

    cd ~
    echo -e "${GREEN} ...cleaning system complete... ${NOCOLOR}"
    df -hT -t ext4

elif [[ $action = '3' ]]
then 

    echo -e "${GREEN} upgrading system... ${NOCOLOR}"
    echo
    echo

    cd ~/matrix-docker-ansible-deploy/
    
    echo -e "${YELLOW} ...pulling latest version of playbook ... ${NOCOLOR}"

    echo 

    git pull

    echo

    sleep 1

    echo -e "${YELLOW} ...pulling roles... ${NOCOLOR}"

    echo 

    just roles

    echo

    sleep 1

    echo -e "${YELLOW} ... running ansible upgrade ... ${NOCOLOR}"
    
    ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start --ask-pass

    echo 

    echo -e "${GREEN} ...ansible upgrade complete... ${NOCOLOR}"
    cd ~

elif [[ $action = '0' ]]
then
    echo 

    sudo systemctl status matrix-synapse

    echo 

fi