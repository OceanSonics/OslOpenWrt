#!/bin/bash

set -u
set -e
set -x

# Update the OpenWrt feeds (https://openwrt.org/docs/guide-developer/feeds):
./scripts/feeds update -a
./scripts/feeds install -a

# Expand the diffconfig into a buildroot config file:
cp diffconfig .config
make defconfig

# Make the SD card images and SDK:
time make download
time make -j24
