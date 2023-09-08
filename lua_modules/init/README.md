# Init

Main entry during bootup.

It initializes LFS, then boots all startup modules mentioned in the device settings using `bootprotect`.

Probably best place to add own logic is to write it in own Lua module and include it at the end of the boot sequence.
