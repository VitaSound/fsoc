Routed nextpnr fit of soft R8051 on Colorlight 5A-75E v6.0 (`LFE5U-25F`, `--25k`, 25 MHz). Columns vary `code` (CODE_BYTES) with the blink console image. Regenerate with `python3 doc/j1-word-graph/build.py fit-8051`. That command is not part of `fsoc --build`.

| | code 4096 | code 8192 | code 16384 |
|---|---:|---:|---:|
| firmware | image full | 4294 / 8192 | 4299 / 16384 |
| LUT4 | — | 12399 / 24288 | 11374 / 24288 |
| logic / carry | — | 11637 / 186 | 10612 / 186 |
| RAM LUT | — | 384 / 3036 | 384 / 3036 |
| DFF | — | 231 / 24288 | 231 / 24288 |
| DP16KD | — | 0 / 56 | 0 / 56 |
| Fmax | image full | 35.44 MHz | 36.65 MHz |
