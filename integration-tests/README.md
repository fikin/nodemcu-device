# Integration tests

It tests end-to-end :

- the startup sequence
- some selected Web functionality

## Running the test

`make integration-test` will execute the test.

Internally makefile prepares a fake SPIFFS under `vendor/test-spiffs`.

## Debugging

In order to debug the integration test:

- prepare the test SPIFFS folder manually `make mock_spiffs_dir`
- use Code settings (or similar) under `.vscode/launch.json` folder when launching the debugger
