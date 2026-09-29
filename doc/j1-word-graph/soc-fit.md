Routed nextpnr fit of the lamp on Colorlight 5A-75E v6.0 (`LFE5U-25F`, `--25k`, 25 MHz). Full and release share the CPU and the RAM array; release only changes how many firmware bytes are used. Regenerate with `python3 doc/j1-word-graph/build.py fit`. That command is not part of `fsoc --build`.

| | j1a full | j1a release | j1b full | j1b release |
|---|---:|---:|---:|---:|
| firmware | 7752 / 8192 | 2822 / 8192 | 9156 / 32768 | 2956 / 32768 |
| LUT4 | 1118 / 24288 | 1118 / 24288 | 3653 / 24288 | 3653 / 24288 |
| logic / carry | 1000 / 118 | 1000 / 118 | 3499 / 154 | 3499 / 154 |
| RAM LUT | 0 / 3036 | 0 / 3036 | 0 / 3036 | 0 / 3036 |
| DFF | 697 / 24288 | 697 / 24288 | 2238 / 24288 | 2238 / 24288 |
| DP16KD | 4 / 56 | 4 / 56 | 16 / 56 | 16 / 56 |
| Fmax | 71.32 MHz | 71.32 MHz | 67.13 MHz | 67.13 MHz |
