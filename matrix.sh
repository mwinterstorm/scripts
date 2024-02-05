#!/bin/bash
# Various Matrix Ansible Commands

#!/bin/bash

GREEN="\033[1;32m"
NOCOLOR="\033[0m"
YELLOW="\033[1;33m"; RED="\033[0;31m"; ENDCOLOR="\033[0m"


echo Matrix updates by Mark
echo
scho Disk report:
df -hT -t ext4
echo
echo Select Action:
echo 1. Clean Database
echo 2. Clean Other - prune docker etc and run clean.sh
echo 3. Upgrade to latest
read -p 'Select Number: ' action

if [[ $action = '1' ]]
then
    echo "${GREEN}cleaning database...${NOCOLOR}"

    echo

    cd ~/matrix-docker-ansible-deploy/
    ansible-playbook -i inventory/hosts setup.yml --tags=run-postgres-vacuum --ask-pass

    echo
    echo "${GREEN}...cleaning database complete${NOCOLOR}"
    echo
    df -hT -t ext4

elif [[ $action = '2' ]]
then 

    echo "${GREEN} cleaning system... ${NOCOLOR}"
    echo
    echo "${YELLOW} ... running docker prune ... ${NOCOLOR}"
    echo

    cd ~/matrix-docker-ansible-deploy/
    ansible-playbook -i inventory/hosts setup.yml --tags=run-docker-prune --ask-pass

    echo 

    echo "${YELLOW} ... docker prune run, running cleaning script ... ${NOCOLOR}"

    echo 

    bash scripts/clean.sh

    echo

    echo "${GREEN} ...cleaning system complete... ${NOCOLOR}"

elif [[ $action = '3' ]]
then 

    echo "${GREEN} upgrading system... ${NOCOLOR}"
    echo
    echo "${YELLOW} ... running ansible upgrade ... ${NOCOLOR}"
    echo

    cd ~/matrix-docker-ansible-deploy/
    ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start --ask-pass

    echo 

    echo "${GREEN} ...ansible upgrade complete... ${NOCOLOR}"

fi