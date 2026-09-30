A cell is `firmware.hex: used bytes of ram`. Debug loads the dictionary layers. Release on soc+blink loads the lamp closure and the compiler roots. Release on soc stays the full console: there is no program to close over.

| project | j1a debug | j1a release | j1b debug | j1b release |
|---|---:|---:|---:|---:|
| soc | 7592 / 8192 | 7592 / 8192 | 8978 / 32768 | 8978 / 32768 |
| soc+blink | 7752 / 8192 | 2822 / 8192 | 9156 / 32768 | 2956 / 32768 |
