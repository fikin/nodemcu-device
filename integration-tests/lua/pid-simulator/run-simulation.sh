#!/bin/bash

declare -r CURRDIR=$( cd $( dirname $0 ) ; pwd )
declare -r PRJDIR=$( cd $( dirname $0 )/../../.. ; pwd )

export LUA_PATH="./?.lua;${PRJDIR}/vendor/nodemcu-lua-mocks/lua/?.lua"
export NODEMCU_MOCKS_SPIFFS_DIR="${CURRDIR}"

_usage() {
    echo "Usage: $ [-pid|-autotune]"
}

if [ $# != 1 ] ; then
    _usage
    exit 1
fi

lua5.3 run${1}-simulation.lua || _usage
