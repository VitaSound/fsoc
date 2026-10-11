# Design: 8051 soft + hard

## Decisions

- One `cpu:` id `8051`. Soft vs hard is option `body` (default from `target:`).
- Soft core: R8051 (Apache-2.0) under `cpu/8051/`. Memory outside the CPU; sizes via options → `params.vh`.
- Soft HEX: two digits per byte (`$readmemh`). Hard HEX: Intel HEX with EOF.
- Code/XDATA overlay on soft: MOVX into `[0, CODE_BYTES)` writes the same array ROM reads (interactive `:`).
- UART soft: SFR `SCON`/`SBUF` bridged to `buart`. LED: `P1.0`.
- Fit: `build.py fit-8051` → `soc-fit-8051.md`; uses existing oss-cad-suite via yosys target.
- Hard host sim: `s51` from `sdcc-ucsim`, not `ucsim-51`.

## Non-goals

- VHDL cores (Light52, Oregano). New `cpu:` per chip package.
- Literals for `8051` in `soc.4th`.
