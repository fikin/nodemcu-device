# mDNS support

This module starts mDNS.

It advertises as `_http._tcp.local`, with `hostname` from `wifi-sta` settings and `properties` from factory settings `fs-mdns.json`.

Current factory properties are set to advertise for [NodeMCU and Home Assistant](https://github.com/fikin/homeassistant-nodemcu).
