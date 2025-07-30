#!/bin/bash
sudo kpartx -av motus-audio-*.img > /tmp/imageparts.txt
for x in `gawk '{print $3}' /tmp/imageparts.txt`; do
    if [[ $gotboot ]]; then
	mkdir ./image_root 2>/dev/null
	sudo mount /dev/mapper/$x ./image_root
    else
	mkdir ./image_boot 2>/dev/null
	sudo mount /dev/mapper/$x ./image_boot
	gotboot=1
    fi
done
