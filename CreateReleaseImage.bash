#!/bin/bash

set -u
set -e
set -x

IMAGE_GZ_PATH='../bin/targets/bcm27xx/bcm2711-glibc/openwrt-21.02-snapshot-r16299-8129aa95f6b-bcm27xx-bcm2711-rpi-4-squashfs-factory.img.gz'
IMAGE_GZ_BASENAME="$(basename ${IMAGE_GZ_PATH})"
IMAGE_IMG_BASENAME="${IMAGE_GZ_BASENAME%.gz}"

# move to the working folder
cd ./ReleaseImage

# copy the SD card image here
cp -v "${IMAGE_GZ_PATH}" .

# extract the SD card image
gunzip "${IMAGE_GZ_BASENAME}"

# append ~1200MB of zeros to the SD card image
dd if=/dev/null "of=${IMAGE_IMG_BASENAME}" bs=1 count=1 seek=1500M

# prep the loop device for the SD card image
LOOP_BLOCK_DEV="$(losetup -f)"
sudo losetup --partscan --find --show "${IMAGE_IMG_BASENAME}"

# Get the partition table information
PART_INFO_JSON="$(sudo sfdisk --json "${LOOP_BLOCK_DEV}")"
SECTOR_SIZE="$(echo "${PART_INFO_JSON}" | jq '.partitiontable.sectorsize')"
MEBIBYTE_SECT="$(((1024**2)/SECTOR_SIZE))"
GIBIBYTE_SECT="$(((1024**3)/SECTOR_SIZE))"
JSON_LASTPART="$(echo "${PART_INFO_JSON}" | jq ".partitiontable.partitions[] | select(.node==\"${LOOP_BLOCK_DEV}p2\")")"
LASTPART_STARTSECT="$(echo "${JSON_LASTPART}" | jq '.start')"
LASTPART_SIZESECT="$(echo "${JSON_LASTPART}" | jq '.size')"

# Plan the partition location for the config partition
CONFIGPART_STARTSECT="$((LASTPART_STARTSECT + LASTPART_SIZESECT + (MEBIBYTE_SECT*4)))"
CONFIGPART_SIZESECT="$((104 * MEBIBYTE_SECT))"

# Plan the partition location for the data partition
DATAPART_STARTSECT="$((CONFIGPART_STARTSECT + CONFIGPART_SIZESECT + (MEBIBYTE_SECT*4)))"
DATAPART_SIZESECT="$((1 * GIBIBYTE_SECT))"

# Create the config partition at the end of the disk
echo "${CONFIGPART_STARTSECT}, ${CONFIGPART_SIZESECT}, 83, -" | sudo sfdisk --append "${LOOP_BLOCK_DEV}"

# Create the data partition at the end of the disk
echo "${DATAPART_STARTSECT}, ${DATAPART_SIZESECT}, 83, -" | sudo sfdisk --append "${LOOP_BLOCK_DEV}"

# Create an ext4 (Only Linux readable) partition on the persistant config (third) partition
sudo mkfs.ext4 -L 'config' "${LOOP_BLOCK_DEV}p3"

# create an exfat (Windows readable) partition in the data partition (fourth)
sudo mkfs.exfat -n 'data' "${LOOP_BLOCK_DEV}p4"

# Mount the config partition and copy a default file into it
# TODO: Deal with mountpoint in exit trap
mkdir ./mnt
sudo mount "${LOOP_BLOCK_DEV}p3" ./mnt
sudo mkdir -pv ./mnt/etc/config/
sudo cp -v ./launchbox.config ./mnt/etc/config/launchbox
sudo umount ./mnt
sudo rm -r ./mnt

# Finally unmount the block device:
sudo losetup -d "${LOOP_BLOCK_DEV}"

# Rename the image file into something consistent:
mv -v "${IMAGE_IMG_BASENAME}" "LaunchBoxSdCard_$(date +'%Y%m%d_%H%M%S').img"
