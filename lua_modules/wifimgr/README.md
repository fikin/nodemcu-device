# Wifi manager

It configures Wifi STA and AP with all settings defined in the device settings.

Then it:

- starts STA-connect process if SSID is being defined in device settings.
  - It repeats to reconnect periodically if disconnected.
- start AP if it stays for too long in disconnected state
  - it shuts down AP once it connects back to some station.
