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
- Removing core dumps, snap leftovers, docker containers (if installed), and Syncthing versioned files (if Syncthing is installed)
- Optional dry-run mode and detailed logging

### Run with
```
sudo bash scripts/clean.sh
```

### Options
```
--dry-run, -n           Perform a trial run without making any changes
--logfile=PATH, -l=PATH Specify a custom path for the log output
--clear-log, -c         Clear the existing log file and exit
--help, -h              Show usage information and exit
--nuclear               EXTREME cleanup: removes man pages, prunes locale files, and aggressively trims journal logs

Environment variables:
VACUUM_SIZE=50M         Set the target size for journal logs
DISK_TYPE=xfs           Filesystem type for reporting (used in legacy mode)
DISK_MOUNT=/            Mount point to check disk usage on (default is /)
TRASH_PATHS="..."       Space-separated paths to empty trash from
KERNEL_KEEP=2           Number of kernel versions to retain (excluding current)
ST_CLEAN_DAYS=14       Days after which Syncthing versioned files will be deleted (default: 7)
```

### Example: Nuclear Cleanup

The `--nuclear` option performs an aggressive cleanup of non-essential files and unused system data. It includes:

- Removal of manual pages (`/usr/share/man`)
- Aggressive journal log truncation (`journalctl --vacuum-size=1M`)
- Locale cleanup using `localepurge`, retaining only `en` and `en_NZ.UTF-8` by default
- Conditional installation of `localepurge` if not already installed
- Logging of actions to the specified or default log file

You can run it like this:
```
sudo bash scripts/clean.sh --nuclear
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
