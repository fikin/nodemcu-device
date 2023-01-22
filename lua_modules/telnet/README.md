# Telnet

Based on nodemcu-firmware [Lua modules](https://github.com/nodemcu/nodemcu-firmware/blob/release/lua_modules/telnet/telnet.lua).

With following changes:

- Audit logging
- Authentication (username and password)
- Protection for single telnet session only (as multiple mess with node input/output pipelines)
