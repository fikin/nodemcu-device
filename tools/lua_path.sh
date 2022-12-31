#!/bin/bash

# builds LUA_PATH string out of vendor/nodemcu-lua-mocks and lua_modules folder trees
_main() {
  cd $( dirname $0 )/..
  local p="${LUA_PATH}"
  for i in $(ls -d vendor/nodemcu-lua-mocks/lua lua_modules/*/fs lua_modules/*/lua) ; do
    i="${i}/?.lua"
    if [ -z "${p}" ] ; then
      p="${i}"
    else
      p="${p};${i}"
    fi
  done
  echo "${p}"
}

_main