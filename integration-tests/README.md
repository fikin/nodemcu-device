# Integration tests

It tests end-to-end :

- the startup sequence
- some selected Web functionality

The testing simulates LFS and SPIFFS experience, which could be used to test for module dependencies.

The test covers boot sequence + some of the IO operations like Web Portal and HASS interactions.

## Running the test

`make integration-test` will execute the test.

Internally makefile prepares a fake SPIFFS under `vendor/test-spiffs`.

## Debugging

In order to debug the integration test:

- prepare the test SPIFFS folder manually `make mock_spiffs_dir`
- use Code settings (or similar) under `.vscode/launch.json` folder when launching the debugger

## LFS and SPIFFS mocking

LFS content is simulated by providing explicit list of Lua files via `NODEMCU_LFS_FILES` env variable.

SPIFFS is constructed out of `<module>/fs` content under `vendor/test-spiffs`.

Makefile automates these settings.
In case of debugging via editor, make sure to do these thinks manually.
