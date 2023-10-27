# scripts
Helpful scripts and tools for managing my servers

Probably not best practice as I am nothing more than an enthusiastic amatuer...

# Scripts
## easyClean
Runs some basic cleaning tasks to hopefully save a little disk space
Asks before prunning docker / snaps

### Run with 
```
sudo bash scripts/clean.sh
```
## easyUpdate
Updates packages

### Run with 
```
sudo bash scripts/update.sh
```

# add to server
### Clone with github
```
gh repo clone mwinterstorm/scripts
```
### or add github if necessary:
```
sudo apt install gh git
gh auth login
gh repo clone mwinterstorm/scripts
```
