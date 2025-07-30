#!/bin/bash
#
# Maintain a list of connected AMPi devices in /run/ampi/dev
#
# This script is run when an ampi logs into the server.
# It creates a symlink like  /run/ampi/dev/HOST -> PORT
# where HOST is ampi-1, ampi-2, ... and PORT is the server port which
# is tunnelled back to the device's ssh port (22).
#
# The symlink is removed when this script exits.
#
# This script is forced to run on device ssh login by the
# clause `command="/opt/ampi/ampilogin.sh"` in the corresponding
# line in /home/ampi/.ssh/authorized_keys. That line also includes
# clauses to set environment variables "ampi_host" and "ampi_port".

LINKDIR=/run/ampi/dev
LINK=$LINKDIR/$ampi_host
LINKTARGET=$ampi_port

function create_link () {
    mkdir -p $LINKDIR
    ln -s -f $LINKTARGET $LINK
}

function remove_link () {
    rm -f $LINK
}

create_link

trap "remove_link" EXIT

while true; do
    sleep 160
done
