# Changelog

## [Unreleased]

## [0.1.1] - 2026-09-24

### Added

- SoC `--build` prints `fsoc: <project> - Start build`, then `Hardware` and `Software`. fhdlgen prints each Verilog include from the top fragment as `fhdlgen: <file>`. The log then says `Hardware complete`, lists the firmware sources and size, says `Software complete`, and `Start emulation` before `sim.sh`. Ctrl+C then prints `Emulation stopped`.
- `projects/soc_blink` starts a Forth loop from `'BOOT` and does not return to the prompt. The loop stores `0` and `1` at `h# 400`, so the `led` port toggles, and waits on the counter at `h# 800`. `FSOC_EMU_CON=term` shows `lamp on` and `lamp off`. `FSOC_EMU_CON=pin` prints only `pin led 0` and `pin led 1`.
- SoC emulation `projects/soc_emul` boots SwapForth J1a. The dictionary is its ANS CORE set without `environment?`, and a line on the UART is answered with ` ok`.
- UART console: `FSOC_EMU_CON=term` writes the byte stream as text. On a tty ncurses shows that text above a host input row; Enter sends the row. `FSOC_EMU_CON=log` keeps `t=<ns> uart <name> <byte>`. Unset follows stdout: a terminal is text, a file stays the log.
- Blinky emulation `main` lives in `fsoc/blinky_main.cpp`. `emu/` keeps only the shared `con` console.
- A project's `target.4th` names its fhdlgen design. That file is the chip composition: `soc_emul` builds `designs/soc_console.4th` (UART, no timer, no `regio`), `soc_blink` builds `designs/soc_top.4th`. Leaf copies follow the design's `` `include `` lines.
- The top module name is the design property `project.top`. `FSOC_SOC_TOP` and `FSOC_BLINKY_TOP` are the output directory; the file is `<dir>/<project.top>.v`. Verilator `--top-module` and Quartus read the same value from `top-module`.
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
