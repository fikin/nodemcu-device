# Device settings

This module offers:

- reading of a json file named `fs-<module>.sjon`.
  - this file is called **factory settings**.
  - it contains stock settings as present in source code repository.
- reading of a json file named `ds-<module>.json`.
  - this file is called **device settings**.
  - it contains user provided changes to factory settings and nothing more.

Other modules are typically using this module to read their settings at startup time.
This is done by using `cfg=require("device-settings")(moduleName)`.

Returned configuration is effectively factory settings merged with device settings.

Having factory and device settings separated allows for safe factory settings upgrade (OTA) without overwriting user provided device settings.

In order to change settings, use `builder=require("factory-settings")(moduleName)` to obtain a builder interface. Once all changes are done, `builder:done()` will save delta changes as new device settings file.

## Source code factory settings

In order to prepackage image with factory settings, expressed as pure code, add them to `user-settings.lua`.

This file is integrated with overall boot sequence and will ensure these settings take effect always.