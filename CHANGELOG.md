# Changelog

## [Unreleased]

### Added

- Blinky emulation `main` lives in `fsoc/blinky_main.cpp`. `emu/` keeps only the shared `con` console.
- `designs/blinky_top.4th` writes `top.v` only to the path the caller passes in `FSOC_BLINKY_TOP`.
- Builder runs from the project directory: `fsoc --build`, `fsoc --load`, `fsoc --build --load`. Task and board come from `projects/*/target.4th`.
- `bin/fsoc` launcher (`FSOC_HOME` + `PATH`), same pattern as fhdlgen.
- Blinky emulation runs under Verilator in realtime until Ctrl+C. Console events are `t=<ns> pin <name> <value>` on change, and `t=<ns> uart <name> <byte>` for a future decoded serial port.
- Working solutions live in `projects/` (`blinky_emul`, `blinky_vitasound_ep4ce10`, `blinky_rz_easyfpga`), each with its own copies of `top.v` / `blinky.v`. Leaf stays in `rtl/`.

## [0.1.0] - 2026-09-23

### Added

- Platform DSL: `platform-new`, `io-begin` / `pins` / `iostd` / `subsignal` / `io-end`, `connector`, `request` / `request-all`.
- Boards: `vitasound_ep4ce10`, `rz_easyfpga`, `ep2c5_mini`.
- Toolchains: Quartus (`.qsf` `.sdc` `build.sh` `load.sh`), Icarus/Verilator sim scripts.
- Blinky target: Verilog + Icarus TB + Quartus project.
- CSR layout, `csr.4th` HAL, `csr.json`; cores uart/gpio/timer/ctrl.
- J1 wrapper + prompt UART model; `fterm`; `hex2readmem`; FOOTSWITCH-SCAN host firmware.
