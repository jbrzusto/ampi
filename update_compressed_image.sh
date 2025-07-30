#!/bin/bash

./umount_image.sh
img=`ls -1 motus-audio-*.img`
cat $img | xz -zc > ${img}.xz
