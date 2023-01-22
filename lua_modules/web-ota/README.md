# Web OTA

Rest based upgrade over air.

It is a plugin for HTTP Server.

It supports http _basic_ authentication.

Clients can issue:

- `GET http://<host>/ota?version` to obtain the current LFS time.
- `POST http://<host>/ota/<file>` to store file in SPIFFS.
  - This can be `*.lc` or `LFS.img`.
- At end of upload, `POST http://<host>/ota?restart` to restart the device.
