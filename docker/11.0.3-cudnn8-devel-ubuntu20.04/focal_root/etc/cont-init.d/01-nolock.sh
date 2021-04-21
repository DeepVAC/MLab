#!/usr/bin/with-contenv bash

set -eu
set -o pipefail

s6-setuidgid $DEEPVAC_USER mkdir -p "$HOME/.config"
s6-setuidgid $DEEPVAC_USER cp /misc/kscreenlockerrc "$HOME/.config/kscreenlockerrc"

#default console
s6-setuidgid $DEEPVAC_USER mkdir -p "$HOME/.local/share/konsole"
s6-setuidgid $DEEPVAC_USER cp /misc/konsolerc "$HOME/.config/konsolerc"
s6-setuidgid $DEEPVAC_USER cp /misc/Default.profile "$HOME/.local/share/konsole/Default.profile"
