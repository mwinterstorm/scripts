# scripts
Helpful scripts and tools for managing my servers

Probably not best practice as I am nothing more than an enthusiastic amatuer...

# Scripts
## easyClean
Runs a comprehensive cleaning script to free up disk space on your system. It includes:
- apt clean, autoclean, autoremove
- Purging old kernels (keeping the latest N, configurable with KERNEL_KEEP)
- Removing orphaned packages
- Cleaning journal logs, rotated logs, and user/disk caches
- Removing core dumps, snap leftovers, docker containers (if installed)
- Optional dry-run mode and detailed logging

### Run with
```
sudo bash scripts/clean.sh
```

### Options
```
--dry-run            Perform a trial run without making changes
--logfile=PATH       Specify a custom path for the log file
--clear-log          Clear the log file and exit
--help               Show usage info

Environment variables:
VACUUM_SIZE=50M      Set journal cleanup target
DISK_TYPE=xfs        Change target disk for reporting
TRASH_PATHS="..."    Specify trash paths to clean
KERNEL_KEEP=2        Number of kernel versions to retain
```

## easyUpdate
Updates packages

### Run with 
```
sudo bash scripts/update.sh
```

## matrix
Various matrix ansible commands for https://github.com/spantaleev/matrix-docker-ansible-deploy

Commands to:
- check system status
- clean DB
- clean system
- upgrade

### Run with 
```
sudo bash scripts/matrix.sh
```

# update
```
cd scripts
git pull
cd ..
```

# add to server
### Clone with github
```
gh repo clone mwinterstorm/scripts
```
### or add github if necessary:
```
sudo apt install gh git
BROWSER=false gh auth login
gh repo clone mwinterstorm/scripts
```
