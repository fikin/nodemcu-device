#!/bin/bash

# overwrite if you want different device
declare -r DEV=$( [ "xx" != "x${DEV}x" ] && echo "${DEV}" || echo "/dev/ttyUSB0" )

flash_it() {
  _runEcho() { echo -e "######\n$@\n------" ; "$@" ; }
  args=""
  for i in "$@" ; do
    addr="$( echo "$i" | awk '{gsub(/.*[/]|[.|-].*/, "", $0)} 1' )"
    args="${args} ${addr} ${i}"
  done
  _runEcho vendor/nodemcu-firmware/tools/toolchains/esptool.py -p ${DEV} -b 460800 write_flash ${args}
}

flash_it "$@"
