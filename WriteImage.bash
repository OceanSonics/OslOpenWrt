#!/bin/bash

set -u
set -e
set -x

# Use the following command to search for image files:
# find ./bin/targets/bcm27xx -type f -name '*-squashfs-factory.img.gz'

# Set variables:
DISK_PATH='/dev/sd???'
IMAGE_ARCHIVE_PATH='./bin/targets/bcm27xx/bcm2711/openwrt-21.02-snapshot-????????'

# Write the image:
sudo dd status=progress conv=fsync bs=2M count=1 "if=/dev/zero" "of=${DISK_PATH}"
gunzip -c "${IMAGE_ARCHIVE_PATH}" | sudo dd status=progress conv=fsync bs=2M "of=${DISK_PATH}"
sync
