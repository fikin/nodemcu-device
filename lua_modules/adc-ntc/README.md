Thermostat connected to A0 input.

Schematic is:

- resistor R1 connected to VCC and A0
- NTC connected to A0 and GND

The default configuration is defined for:

- VccR1=5V
- R1=330k
- Rntc=50k
- NodeMCU board

_Note: stock ESP8266 chip accepts 1V in A0 input. NodeMCU boards are shipped with built-in voltage divider and accept 3.3V._

Since resistor and voltage values are not perfect, there are some discrepancies between schematic and reality.
There are two way to influence for biased results:

- Adjust R1 resistor value in the settings.
  - With default configuration, each +15k => +1C.
- Use `correction factor`.
  - Correction factor is ADC value added to A0 reading before Vntc is being calculated.
  - With default configuration, +9 => +1C.

Perform temperature calibration or observe long term and adjust these if you see fit.

$Vstep = VccA0 / 1023$

$AdcValue = A0 + correction_factor$

$Vntc = Vstep * AdvValue$

$Rntc = R1 * Vntc / ( VccR1 - Vntc )$

$TempK = A + B * ln(Rntc) + C * ln(Rntc)^3$

$TempC = TempK - 273.15$

With default configuration following values could be expected:

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
