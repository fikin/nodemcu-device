# NodeMCU Device

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [NodeMCU Device](#nodemcu-device)
  - [Building instructions](#building-instructions)
  - [Some build setup explanations](#some-build-setup-explanations)
    - [First time NodeMCU device flashing](#first-time-nodemcu-device-flashing)
    - [First time NodeMCU flashing](#first-time-nodemcu-flashing)
    - [Consequent LFS updates](#consequent-lfs-updates)
  - [Flashing NodeMCU sw for first time](#flashing-nodemcu-sw-for-first-time)
    - [Preparing firmware image(s) manually](#preparing-firmware-images-manually)
    - [Flashing firmware image(s)](#flashing-firmware-images)
    - [Determining SPIFFS partition table](#determining-spiffs-partition-table)
    - [Preparing SPIFFS image](#preparing-spiffs-image)

<!-- /code_chunk_output -->

Traditionally, programming for [NodeMCU](https://en.wikipedia.org/wiki/NodeMCU) has been rather constrained given the limited space pf RAM (up to ~44kB for heap space for data and code).

But with introduction of [LFS](https://nodemcu.readthedocs.io/en/release/lfs/) support, code and constants can live now in flash ROM. And available heap would remain for computation data only.

This allow us to pack just about enough functionality to make NodeMCU behave like a real internet device.

This repository contains collection of Lua modules and build scripts to prepare firmware, LFS and SPIFFS images for NodeMCU.

Provided so far are (check [lua_modules dir](lua_modules) for up to date list):

- boot manager with restart protection
- wifi connectivity manager with captive portal
- logger
- programmable web REST server
- OTA (LFS and parts of SPIFFS upgrade Over The Air)
- programmable HomeAssistant integration
- telnet
- ...

*Some of the modules were created by other authors, here they are included for convenience during packaging.*

Note: I'm testing these with ESP8266, for ESP32 I haven't had time to check yet.

## Building instructions

1. Clone this repo
2. Tune `build.config` if you find a need. Specifically the included `modules`.
3. `make config` to generate the build config input.
4. `make prepare-firmware` to patch firmware headers with needed into. And to prepare `nodemcu-firmware/local` folder content.
*4.1. Make sure you can compile firmware [locally](https://nodemcu.readthedocs.io/en/latest/build/#linux-build-environment).*
5. `make build` to produce images in `nodemcu-firmware/bin` folder.
6. Flash the images to NodeMCU device

On first boot, the device will flash `LFS.img`, packaged inside SPIFFS and reboot again.

After that second reboot, the device will run its defined boot init sequence.

## Some build setup explanations

Build is using [nodemcu-custom-build](https://github.com/fikin/nodemcu-custom-build) to patch `nodemcu-firmware` header files. This choice is long term bet into getting this functionality to NodeMCU cloud building support.

Build is cloning `nodemcu-custom-build` and `nodemcu-firmware` repos in respective subdirs. One can symlink them if more advanced use is needed.

Images are built using `nodemcu-firmware` tools and default setup. This means that:

- all `local/lua` files are packaged into `local/fs/LFS.img`
- all `local/fs` files are packages into SPIFFS image `bin/0x100000-0x40000.img` (subject to address and size settings in `build.config`).
- actual firmware is built into `bin/{0x00000.bin,0x10000.bin}`.

All Lua modules are structured in [lua_modules](lua_modules) subdir. Subfolder structure follows same notation: `<module>/lua` files will end up in LFS image, `<module>/fs` files will end up in SPIFFS.
