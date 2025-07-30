#!/bin/bash

# Set-up script for a raspberry Pi to run the motus_audio capture
# program.
#
# This file must be idempotent: running it more than once leads to the
# same configuration as running it just once.

## update package lists
sudo apt update
sudo apt install -y ffmpeg flac jq socat sqlite3 chrony

curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

sudo mkdir /opt/ampi /data
sudo chown pi:pi /opt/ampi /data

# on PC:

cd ~/proj/AMPi
scp \
    01-audiomoth.rules \
    amazon_secrets.txt \
    amcmd \
    ampi-capture@.service \
    ampi_capture.sh \
    ampi-capture@.yml \
    ampi_common.sh \
    ampi_config.default \
    ampi_config.sqlite \
    ampi_login.sh \
    am_wrangle.sh \
    bluetooth-autopair.service \
    bluetooth_autopair.sh \
    bluetooth.service \
    config_menu.sh \
    dot_root_bash_login
    nfc_amazon_secrets.txt \
    queued-uploader.service \
    queued_uploader.sh \
    setpar \
    shiftwrapd \
pi@ampi:

cd ~/proj/shiftwrap
scp scripts/sw systemd/* pi@ampi:

# on Pi:
sudo cp *.service /etc/systemd/system
sudo mkdir -p /etc/shiftwrap/services
sudo cp shiftwrap.yml /etc/shiftwrap
sudo cp ampi-capture@.yml /etc/shiftwrap/services
sudo cp amcmd shiftwrapd sw /usr/bin
sudo cp 01-audiomoth.rules /etc/udev/rules.d
sudo cp dot_root_bash_login /root/.bash_login
cp am*.sh ampi_config* amazon_secrets.txt bluetooth_autopair.sh config_menu.sh queued_uploader.sh setpar /opt/ampi
sudo udevadm control --reload-rules
sudo systemctl daemon-reload
sudo systemctl enable --now shiftwrapd
sudo systemctl enable --now bluetooth-autopair
echo Unconfigured | sudo tee /etc/sitename
sudo touch /root/.hushlogin
echo -n | sudo tee /etc/motd
echo "set +m" >> /root/.bashrc
...
