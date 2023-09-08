# Bootstrap

To be called at boot time to execute one-time configuration actions.

Typically used in sw upgrade use cases.

In case there is a need to one-off configuration during next reboot,
place commands in a file called `bootstrap-sw.lua` and reboot the device.

It such file and if it exists:

- runs it
- captures all errors into `bootstrap-sw.PANIC.txt`
- removes it regardless of execution status, so next reboot does not take place
