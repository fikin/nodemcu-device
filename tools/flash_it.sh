#!/bin/bash

# overwrite if you want different device
declare -r DEV=$( [ "xx" != "x${DEV}x" ] && echo "${DEV}" || echo "/dev/ttyUSB0" )

_runEcho() { echo -e "######\n$@\n------" ; "$@" ; }

_flash_esp8266() {
  _runEcho vendor/nodemcu-firmware/tools/toolchains/esptool.py -p ${DEV} -b 460800 write_flash "$@"
}

_flash_esp32() {
	_runEcho vendor/nodemcu-firmware/sdk/esp32-esp-idf/components/esptool_py/esptool/esptool.py \
    -p ${DEV} -b 460800 \
    --before default_reset \
    --after hard_reset \
    --chip esp32  \
    write_flash \
    --flash_mode dio \
    --flash_size detect \
    --flash_freq 40m \
    0x1000 build/bootloader/bootloader.bin \
    0x8000 build/partition_table/partition-table.bin \
    0x10000 build/nodemcu.bin
}

flash_it() {
  args=""
  for i in "$@" ; do
    addr="$( echo "$i" | awk '{gsub(/.*[/]|[.|-].*/, "", $0)} 1' )"
    args="${args} ${addr} ${i}"
  done
  _flash_esp8266 ${args}
}

flash_it "$@"
