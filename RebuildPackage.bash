#!/bin/bash

set -u
set -e
set -x

# Update the OpenWrt feeds (https://openwrt.org/docs/guide-developer/feeds):
./scripts/feeds update OslFeeds
./scripts/feeds install OslFeeds

make package/LaunchBoxRoot/clean
make package/LaunchBoxRoot/compile
# make package/LaunchBoxRoot/install

make package/index
