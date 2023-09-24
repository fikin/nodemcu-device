Thermostat connected to A0 input.

Schematic is:

- resistor R1 connected to VCC and A0
- NTC connected to A0 and GND

The default configuration is defined for:

- VCC=5V
- R1=330k
- Rntc=50k

$Vntc = VCC * Rntc / ( Rntc + R1 )$

$Adc = 1023 * Vntc / 3.3$

where 1023 is Adc resolution and 3.3V is the A0 input max voltage i.e. NodeMCU board. Plain ESP8266 chips accept 1v max.

| Temp (C) | Rntc (kOhm) | Vntc (V) | Adc (0-1024) |
| -------- | ----------- | -------- | ------------ |
| -20C     | 500         | 3.01     | 934          |
| 0C       | 175         | 1.73     | 537          |
| +20C     | 50          | 0.66     | 204          |
| +35C     | 30          | 0.42     | 129          |

Various tutorials can be used as reference and background information. For example:

- [esp8266-ntc-temperature-thermistor](https://esp8266tutorials.blogspot.com/2016/09/esp8266-ntc-temperature-thermistor.html)
- [nodemcu thermistor](https://www.electronicwings.com/nodemcu/thermistor-interfacing-with-nodemcu)
  - this one is having different schematics though
- [ntc-temperature-sensor](https://www.electronicdiys.com/2020/05/ntc-temperature-sensor-with-arduino-esp.html)

For calculating coefficients one can use:

- [NTC Calculator](https://www.thinksrs.com/downloads/programs/Therm%20Calc/NTCCalibrator/NTCcalculator.htm)
- [Thermistor 50K resistance table](https://www.bapihvac.com/wp-content/uploads/2010/11/Thermistor_50K.pdf)
- [TS104 50k resistance table](https://mcshaneinc.com/html/TS104_Specs.html?NewWin)
