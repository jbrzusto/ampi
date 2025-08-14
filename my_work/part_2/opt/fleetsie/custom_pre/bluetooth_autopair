#!/bin/bash

# automatically pair with any bluetooth device
# when a device is connected, launch rfcomm
# when a device is disconnected, kill rfcomm and agetty

while true; do
    if pgrep bluetoothd; then
        break
    fi
    sleep 1
done

sleep 1
hciconfig hci0 name "`hostname`"
coproc BT { bluetoothctl 2>&1; }

printf "discoverable on\npairable on\nagent on\ndefault-agent\n" >&${BT[1]}

while true; do
    read x <&${BT[0]}
    if [[ "$x" =~ "Request confirmation" ]]; then
        printf "yes\n" >&${BT[1]}
    elif [[ "$x" =~ "Connected: no" ]]; then
        killall -q -KILL rfcomm
        killall -q -KILL agetty
        fuser -s -k /dev/rfcomm0
    elif [[ "$x" =~ "Connected: yes" ]]; then
        if ! pgrep -f "rfcomm watch hci0"; then
	    while true; do
		if [[ -e /sys/class/bluetooth/hci0 ]]; then
                    break
                fi
	        sleep 1
            done
            rfcomm watch hci0 1 agetty -c -i -I "\\12\\12Login as root with the usual password\\12" rfcomm0 &
        fi
    fi
    sleep 1
done
