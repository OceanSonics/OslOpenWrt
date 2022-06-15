# Ocean Sonics Specific Notes

## Branch notes

This branch should descend from the OpenWrt upstream branch `openwrt-21.02`
Note that OpenWrt release 21.02 is currently not fully release, but is on its
fourth release candidate, so once release happens, make sure to pull those changes.

## How to synchronize this repository with upstream OpenWrt

Make sure you're checked out into this (`osl-rpicm4`) branch.

```bash
# Clone this repository and checkout this branch if you haven't already:
git clone git@github.com:OceanSonics/OslOpenWrt.git
cd OslOpenWrt
git checkout osl-rpicm4

# Add the OpenWrt repo as an upstream, and merge in their changes.
git remote add upstream https://git.openwrt.org/openwrt/openwrt.git
git fetch upstream
git merge upstream/openwrt-21.02

# TODO: write how to push these changes to our Github.
```

## How to use the OpenWrt image customization tools

See these links:

- <https://openwrt.org/docs/guide-developer/build-system/use-buildsystem>
- <https://openwrt.org/toh/raspberry_pi_foundation/raspberry_pi>
- <https://openwrt.org/docs/guide-developer/using_the_sdk>

## How to configure the menuconfig

Generally, we want something that matches this:

- Target system: `Broadcom BCM27xx`
- Subtarget: `BCM2711 boards (64 bit)`
- Target Profile: `Raspberry Pi 4B/400/4CM (64bit)`

The official unmodified release of this OpenWrt image and SDK can be located here:
<https://downloads.openwrt.org/releases/21.02.0-rc4/targets/bcm27xx/bcm2711/>

Our diffconfig is based upon the default release configuration of OpenWrt for
the `Raspberry Pi 4B/400/4CM` target, this was obtained like so:

```bash
wget https://downloads.openwrt.org/releases/21.02.0-rc4/targets/bcm27xx/bcm2711/config.buildinfo  -O .config
```

You shouldn't have to re-download the default build configuration since this
repository contains our own custom configuration derived from it.

```bash
# Install the system dependencies required:
sudo apt update
sudo apt install build-essential ccache ecj fastjar file g++ gawk \
gettext git java-propose-classpath libelf-dev libncurses5-dev \
libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget \
python3-distutils python3-setuptools python3-dev rsync subversion \
swig time xsltproc zlib1g-dev

# Clone this repository and checkout this branch if you haven't already:
git clone git@github.com:OceanSonics/OslOpenWrt.git
cd OslOpenWrt
git checkout osl-rpicm4

# Update the OpenWrt feeds (https://openwrt.org/docs/guide-developer/feeds):
sudo ./scripts/feeds update -a
sudo ./scripts/feeds install -a

# Expand the diffconfig into a buildroot config file:
cp diffconfig .config
make defconfig

# Make the SD card images and SDK:
make download
make -j8

# The resulting images and SDK will be located at ./bin/targets/bcm27xx/bcm2711-glibc/

# Create a backup of the images:
tar cf "./oslwrt_rpicm4_$(date +%b-%d-%Y-%s).tar" './bin/targets/bcm27xx/bcm2711-glibc/'

# Flash the image to an SD card or a SoM's onboard eMMC:

# (If needed) Put the SoM into eMMC mass storage passthrough mode:
# Install libusb (Ubuntu: sudo apt install libusb-1.0-0-dev)
# TODO: Write this in a different section, since you also need to flip a switch on the carrier board, use the right USB port, it's probably better that you install the rpiboot tool outside this directory structure, etc.

git clone --depth=1 https://github.com/raspberrypi/usbboot
cd usbboot
make
sudo ./rpiboot

# Make sure to use `dmesg` to figure out where the eMMC was mounted, will be a /dev/sda, /dev/sdb, etc. device.
DISK_PATH='/dev/sd???'
IMAGE_ARCHIVE_PATH="$(find ./bin/targets/bcm27xx/bcm2711/ -type f -name '*-ext4-sysupgrade.img.gz')"
sudo dd status=progress conv=fsync bs=2M count=1 "if=/dev/zero" "of=${DISK_PATH}"
gunzip -c "${IMAGE_ARCHIVE_PATH}" | sudo dd status=progress conv=fsync bs=2M "of=${DISK_PATH}"
sync
```

## How to add and remove target programs and libraries

```bash
# Make your changes in makeconfig or xconfig, then save and exit:
make xconfig

# Write the changes to the diffconfig:
./scripts/diffconfig.sh > diffconfig

# Rebuild the image:
make download
make -j8
```

## How to modify the default filesystem

TODO: Finish writing this.

### Notable files

- WiFi firmware files should live in `./files/lib/firmware/brcm/`

## Copyrighted WiFi firmware firmware binaries

- The WiFi driver used by the Raspberry Pi CM4: <https://wireless.wiki.kernel.org/en/users/Drivers/brcm80211>
  - Specifically, we're using the `brcmfmac` driver for WiFi cards with full MAC capability.
- Linux's third-party vendor firmware binaries repository: <https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git>

Long story short is that the onboard WiFi module doesn't work without having it's own vendor firmware uploaded on power-on, that firmware needs to be included with the Linux driver handling the module. Because of various copyright laws, this isn't provided by OpenWrt, but has to be obtained from the Linux foundation directly.

```text
[ 1554.471326] brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac43455-sdio for chip BCM4345/6
[ 1554.480632] brcmfmac mmc1:0001:1: Direct firmware load for brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.txt failed with error -2
[ 1554.492935] brcmfmac mmc1:0001:1: Falling back to sysfs fallback for: brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.txt
[ 1554.508277] brcmfmac mmc1:0001:1: Direct firmware load for brcm/brcmfmac43455-sdio.txt failed with error -2
[ 1554.518041] brcmfmac mmc1:0001:1: Falling back to sysfs fallback for: brcm/brcmfmac43455-sdio.txt
[ 1559.524253] usbcore: registered new interface driver brcmfmac
[ 1560.536173] brcmfmac: brcmf_sdio_htclk: HT Avail timeout (1000000): clkctl 0x50
```

WiFi firmware files should live in `./files/lib/firmware/brcm/`

To obtain/update the WiFi firmware files, run these commands starting from this repository:

```bash
cd ..
git clone git@github.com:RPi-Distro/firmware-nonfree.git
cd ./OslOpenWrt
mkdir -vp ./files/lib/firmware
cp -v ../firmware-nonfree/LICENCE.broadcom_bcm43xx ./files/lib/firmware
cp -rv ../firmware-nonfree/brcm ./files/lib/firmware
```

TODO: Finish writing this.

## Configuring UARTs to hook up a GPS module

- Official docs: <https://www.raspberrypi.org/documentation/computers/configuration.html#configuring-uarts>
- Peripherals guide: <https://datasheets.raspberrypi.org/bcm2711/bcm2711-peripherals.pdf>
- Arm PrimeCell UART (PL011) manual: <https://developer.arm.com/documentation/ddi0183/g/>
- https://raspberrypi.stackexchange.com/questions/99954/pi-4-i-o-interface-options-and-where-to-find-them

Long story short, it looks like you need to add a device tree overlay to enable other UARTs.

There are some weird quirks with the "mini UART" unit in the SoC that seems to make it not very useful.
We don't want to use it, but this just means that you shouldn't use `UART1`.

We want to use the ARM PL011 UART controllers, quoting the peripherals guide:

```text
The BCM2711 device has six UARTs. One mini UART (UART1) and five PL011 UARTs (UART0, UART2, UART3, UART4 &
UART5). This section describes the PL011 UARTs. 
```

So this is how we want to use our UARTs:

- `UART0`: Linux boot console: `/dev/ttyAMA0`
  - `TXD0`, `GPIO14`, Header pin 8
  - `RXD0`, `GPIO15`, Header pin 10
- `UART1`: This is a mini UART, DON'T use it!!!
- `UART2`: Pins don't work out
- `UART3`: External GPS: `/dev/ttyAMA1`
  - `TXD3`, `GPIO4`, Header pin 7
  - `RXD3`, `GPIO5`, Header pin 29

```text
Add this to /boot/config.txt or maybe /boot/distroconfig.txt
It's okay to have multiple dtoverlay lines.

[cm4]
# OSL: Enable UART3 for external GPS module.
dtoverlay=uart3,txd3_pin=4,rxd3_pin=5
```

## How to modify the default UCI settings

- <https://openwrt.org/docs/guide-developer/uci-defaults>

## How to tweak, create, and develop our custom packages

- <https://openwrt.org/docs/guide-developer/feeds>
- <https://openwrt.org/docs/guide-developer/packages>

```bash
./scripts/feeds update OslFeeds
./scripts/feeds install -a -p OslFeeds
make xconfig
```
