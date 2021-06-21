#!/bin/bash

# Default user/group, default password is "password"
groupadd --gid 1000 $DEEPVAC_USER
GEMFIELD_PASSWORD=$(openssl passwd -1 -salt ADUODeAy $DEEPVAC_PASSWORD)
useradd --uid 1000 --gid 1000 --groups video -ms /bin/bash $DEEPVAC_USER && \
    echo "$DEEPVAC_USER:$GEMFIELD_PASSWORD" | chpasswd -e

# Create home diretory
chown $DEEPVAC_USER:$DEEPVAC_USER "$HOME"

# Setup
echo "Add sudo to $DEEPVAC_USER..."
echo "$DEEPVAC_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/default
