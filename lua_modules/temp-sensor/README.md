# Temp sensor

Home Assistant temperature sensor based on DS18B20.

Other modules can use it independently from HASS. Reading current temp is done via `require("temp-sensor-get")()`.

Increase "filterSize" if the temp input is ADC-NTC or similar.
