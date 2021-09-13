#!/bin/bash

set -u
set -e
set -x

# create a working folder
mkdir ./ReleaseImage

# move to the working folder
cd ./ReleaseImage

# copy the SD card image here
cp -v ../bin/targets/bcm27xx/bcm2711-glibc/openwrt-21.02-snapshot-r16299-8129aa95f6b-bcm27xx-bcm2711-rpi-4-squashfs-factory.img.gz .

# extract the SD card image
gunzip openwrt-21.02-snapshot-r16299-8129aa95f6b-bcm27xx-bcm2711-rpi-4-squashfs-factory.img.gz

# append ~1200MB of zeros to the SD card image
dd if=/dev/null of=openwrt-21.02-snapshot-r16299-8129aa95f6b-bcm27xx-bcm2711-rpi-4-squashfs-factory.img bs=1 count=1 seek=1500M

# prep the loop device for the SD card image
sudo losetup --partscan --find --show openwrt-21.02-snapshot-r16299-8129aa95f6b-bcm27xx-bcm2711-rpi-4-squashfs-factory.img

# create a 100MB partition at the end of the disk

# create a 1000MB partition at the end of the disk

# Create an exfat partition on the persistant config (third) partition
sudo mkfs.exfat -n 'persist-config' /dev/loop1p3

# create an exfat partition in the data partition (fourth)
sudo mkfs.exfat -n 'data' /dev/loop1p4

# Unmount the disk image
sudo losetup -d /dev/loop1