# Web Home Assistant

Rest wed module (plugin for HTTP server) serving all Home Assistant interactions.

Serves all HASS functionality under `http://<host>/api/ha` path.

Integrates with [Home Assistant NodeMCU integration](https://github.com/fikin/homeassistant-nodemcu).

It supports _basic_ authentication.

Integrate in HASS using following URL : `http://<user>:<pswd>@<host>/api/ha`.

Enable which HASS entities are to be integrated (see factory settings).
