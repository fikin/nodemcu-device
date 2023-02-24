# VSCode settings

Here are some hints how to maintain code launch settings, so debugging can be performed.

## maintaining "NODEMCU_LFS_FILES"

```shell
ls lua_modules/*/lua/*.lua | awk '{printf $1" "}'
```

Update the NODEMCU_LFS_FILES value with the resulting text.

## maintaining "path" for "Nodemcu-device Unit Test" configuration

```shell
ls -d lua_modules/*/{fs,lua}/*.lua | xargs dirname | sort -u  | awk '{print "\"\${workspaceFolder}/"$1"/?.lua\","}'
```

Replace all paths featuring `lua_modules` with the resulted list. 

Keep following at the end of the list:

```
    "${workspaceFolder}/vendor/nodemcu-lua-mocks/lua/?.lua"
```