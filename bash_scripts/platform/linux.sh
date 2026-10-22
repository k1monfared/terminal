# platform/linux.sh - loaded on any Linux (Ubuntu, MATE, GNOME, ...). Not loaded on macOS.

## input method (ibus)
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus

## hibernation
alias hib='sudo systemctl hibernate'

## gnome remote desktop (RDP on port 3389). Quick toggle for security.
alias remote_on='systemctl --user enable --now gnome-remote-desktop.service'
alias remote_off='systemctl --user disable --now gnome-remote-desktop.service'
alias remote_status='systemctl --user is-active gnome-remote-desktop.service'

## hardware helpers (X11 / intel backlight)
alias rotate="sh $bashscripts/rotate.sh"
alias brightness="sh $bashscripts/brightness.sh"
alias procmon="bash $bashscripts/procmon.sh"      # needs sysstat (pidstat)
alias vnc="$HOME/opt/vnc-manager.sh"
