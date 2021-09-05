#define bashscripts folder address in the ~/.bashrc and then source this file there. e.g.
# bashscripts="/home/$USER/bash_scripts"
# source "$bashscripts/.bashrc"

#apt aliases
alias ins="sudo apt install"
alias upd="sudo apt update"
alias upg="sudo apt upgrade"
alias remove="sudo apt remove"

#note aliases
alias note="sh $bashscripts/note.sh"
alias n="sh $bashscripts/quicknote.sh"
alias ln="sh $bashscripts/lastnote.sh"
alias drafts="sh $bashscripts/searchdrafts.sh"

#github gist aliases
alias gist="sh $bashscripts/gist.sh"
alias gistp="sh $bashscripts/publicgist.sh"
alias g="sh $bashscripts/quickgist.sh"

#quick commit and push to git
alias gitall="git status && git add --all && git commit && git push"

# solving ibus access problem
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus

#hibernation
alias hib='sudo systemctl hibernate'
