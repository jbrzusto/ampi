#!/bin/bash
sudo umount ./image_root
sudo umount ./image_boot
sudo kpartx -d ./motus-audio-*.img
