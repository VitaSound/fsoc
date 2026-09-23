# Changelog

## [Unreleased]

### Added

- `bin/fsoc` launcher (`FSOC_HOME` + `PATH`), same pattern as fhdlgen.
- Blinky path 2: pure [`rtl/blinky.v`](rtl/blinky.v) + [`designs/blinky.4th`](designs/blinky.4th); emit copies RTL and maps board pins in `.qsf` (no Verilog module body as Forth strings).

## [0.1.0] - 2026-09-23

### Added

- Platform DSL: `platform-new`, `io-begin` / `pins` / `iostd` / `subsignal` / `io-end`, `connector`, `request` / `request-all`.
- Boards: `vitasound_ep4ce10`, `rz_easyfpga`, `ep2c5_mini`.
- Toolchains: Quartus (`.qsf` `.sdc` `build.sh` `load.sh`), Icarus/Verilator sim scripts.
- Blinky target: Verilog + Icarus TB + Quartus project.
- CSR layout, `csr.4th` HAL, `csr.json`; cores uart/gpio/timer/ctrl.
- J1 wrapper + prompt UART model; `fterm`; `hex2readmem`; FOOTSWITCH-SCAN host firmware.
