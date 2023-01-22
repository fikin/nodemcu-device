# Dummy strings

Package to prepackage all text strings which are mentioned in the source code.

This is basically [nodemcu-firmware examples](https://github.com/nodemcu/nodemcu-firmware/blob/release/lua_examples/lfs/dummy_strings.lua).

By creating this module and packaging it inside LFS, RAM footprint for all text constants drops.

When you develop new functionality, run `require("dummy-strings")()` and update the source code with new additions.
Then remake LFS image.
