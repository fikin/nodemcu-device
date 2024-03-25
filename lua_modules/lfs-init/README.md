# Init LFS

This is largely based on nodemcu-firmware examples and other sources.

During boot process LFS would have to be initialized.

This module will pre-create `require` loaders to use LFS too.

And if SPIFFS contains `LFS.img` file, it will auto-flash it.

In case of success, `LFS.img` will be removed.

In case of LFS flash error, `LFS.img` will be removed and `LFS.img.PANIC.txt` will contain `node` reboot error.
