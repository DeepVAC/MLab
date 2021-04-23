#!/usr/bin/with-contenv bash

set -eu
set -o pipefail

useradd -U -u $PUID -d "$HOME" -s /bin/bash $DEEPVAC_USER
# groupmod -o -g "$PGID" $DEEPVAC_USER
# usermod -o -u "$PUID" $DEEPVAC_USER
echo "$DEEPVAC_USER:$DEEPVAC_PASSWORD" | chpasswd
echo "root:$ROOT_PASSWORD" | chpasswd


# Link /root -> $HOME
# for compatibility reasons
if [[ "$PGID" -eq 0 ]] && [[ "$PUID" -eq 0 ]]
then
  if [[ ! -e "$HOME" ]]
  then
    ln -s /root "$HOME"
  fi
else
  mkdir -p "$HOME"
fi

#add to sudo
usermod -aG sudo $DEEPVAC_USER
echo "gemfield ALL=(ALL:ALL) ALL"  >> /etc/sudoers
#echo 'gemfield ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 

echo "GEMFIELD: may take long time if $HOME has too many files..."
chown $DEEPVAC_USER:$DEEPVAC_USER -R "$HOME"
#XDG_RUNTIME_DIR
mkdir -p /run/gemfield
chown $DEEPVAC_USER:$DEEPVAC_USER /run/gemfield
chmod 7700 /run/gemfield

#vnc
mkdir -p $HOME/.vnc
echo gemfieldvnc | vncpasswd -f > $HOME/.vnc/passwd
chown -R $DEEPVAC_USER:$DEEPVAC_USER $HOME/.vnc
chmod 0600 $HOME/.vnc/passwd

#kde
cp /deepvac.png $HOME/.face.icon
mkdir -p $HOME/.config/
chown -R $DEEPVAC_USER:$DEEPVAC_USER $HOME/.config

cat <<EOT >> $HOME/.config/kdeglobals
[KDE]
ColorScheme=BreezeLight
SingleClick=false
contrast=4
widgetStyle=Breeze
EOT

cat <<EOT >> $HOME/.config/kwinrc
[Compositing]
Enabled=false
EOT

#MLab code DNS
if [ -z "$MLAB_DNS" ]
then
  echo "[GEMFIELD] Warning: you may forget set MLAB_DNS"
else
  echo $MLAB_DNS >> /etc/hosts
fi
