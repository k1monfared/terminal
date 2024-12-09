# bash_scripts
Some of the bash scripts that I use on a daily basis

## bashrc_aliases
define bashscripts folder address in the ~/.bashrc and then source this file there. e.g.
```
bashscripts="/home/$USER/bash_scripts"
source "$bashscripts/bashrc_aliases"
export PATH="$PATH:$bashscripts"
```

### to access this file without looking for it every time
- `aliases_edit`: opens it in an text editor
- `aliases_list`: prints them all in the terminal

### system
#### solving ibus access problem

#### hibernation
- `hib`: hibernates, currently has some issues.

#### shortcuts
- `search`: search in duckduckgo and open in firefox
- `contacts`: search in contacts
- `mic`: start recording voice
- `organize`: organize photos of this folder into monthly folders
- `jnb`: start jupyter notebook
- `cb`: copy content of the file to clipboard

### todo.txt
- `t`: run todo.txt

### apt
- `ins`: install package
- `upd`: update repositories
- `upg`: upgrade all upgradable packages
- `remove`: remove package

### note
- `note`: start a note doc
- `n`: write a quick note into a file
- `ln`: open the last note
- `drafts`: search in notes

### github
- `git_switch`: switch git account
- `git_who`: announce the active git account
- `git_init`: initialize a repo
- `git_push_all`: add all files, commit with no message, push
- `git_activate`: activate a git account
- `git_clone`: clone a repo


#### github gist
- `gist`: create a gist
- `gistp`: creat a public gist
- `gg`: quickly publish gist


### libarary
This requires the `overdrive.sh` file provided in the `overdrive` folder. and it requires it to be in a certain folder to be accessed.
- `libby`: download the audiobook normally
- `libby_list`: list all available audiobooks to be downloaded
    - the list of `.odm` files in the `~/Downloads` folder
- `libby_get`: download particular audiobook in the designated folder
    - If the `.odm.license` anbd the `.odm.metadata` files are next to the `.odm` file, it uses them



### vpn
#### proton
- `ppn`: proton vpn cli


### passowrds
#### bitwarden
- `bw`: run bitwarden cli
- `bwc`: copy password
- `bwu`: unlock session
- `bwl`: lock session
