#!/bin/bash

# create a working folder
mkdir ~/ReleaseImage

# move to the working folder
cd ~/ReleaseImage

# copy the SD card image here

# extract the SD card image

# append ~1200MB of zeros to the SD card image

# prep the loop device for the SD card image
losetup --partscan --find --show disk.img

# create a 100MB partition at the end of the disk

# create a 1000MB partition at the end of the disk

# Create an exfat partition on the persistant config (third) partition

# create an exfat partition in the data partition (fourth)

# Unmount the disk image
losetup -d /dev/loop0