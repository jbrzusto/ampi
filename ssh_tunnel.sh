#!/bin/bash
#
# set up ssh tunnels:
#   - map this device's reserved port the whofliesby.org server back to the ssh port on this device
#   - map port 10051 on this device to port 10051 on the wfb server (zabbix)
#
# This script is launched from a systemd service.
# This script creates a low-bandwidth task running on the server whose job is to maintain dynamic
# connection information there.  When this script exists, it should be restarted by its systemd service.
AM_SHARED_FILE=/opt/ampi/ampi_common.sh
if [[ ! -f $AM_SHARED_FILE ]]; then
    echo "Can't find shared code file $AM_SHARED_FILE"
    exit 100
fi
. $AM_SHARED_FILE
get_conf TUNNEL_PORT tunnel.port
if [[ ! $TUNNEL_PORT ]]; then
    echo "No tunnel port assigned to this device - can't set up tunnel from cloud"
    exit
fi
get_conf USER_AT_HOST user.at.host
if [[ ! $USER_AT_HOST ]]; then
    echo "No cloud user and server configured for this device - can't connect to cloud"
    exit
fi
ssh -oExitOnForwardFailure=yes -oControlMaster=auto -oControlPath=/tmp/ssh.wfb -Rlocalhost:${TUNNEL_PORT}:localhost:22 -L10051:localhost:10051 $USER_AT_HOST
