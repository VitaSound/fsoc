# Changelog

## [Unreleased]

## [0.3.0] - 2026-09-25

### Added

- `projects/soc_vitasound_ep4ce10` writes Quartus files and `firmware.hex`. `--build` does not run Quartus; `--load` runs `load.sh`. `fterm` opens a device path (`gforth tools/fterm.4th /dev/ttyUSB0`); without a path it still answers `ok` from memory.
- Board clock: `io.clock-hz` / `plat-clock-hz` (50 MHz on `clk50`). Quartus maps `serial` subsignals (`quartus-map-sub`: `PIN_114` → `uart_tx`, `PIN_115` → `uart_rx`). Design parameter `BOARD=1` ties `rst` and `dump` to 0.

### Changed

- **BREAKING** SoC UART divider follows `CLK_HZ/BAUD` (50 MHz / 115200). Emulation no longer hard-codes 104 clocks/bit.

### Notes

- Quartus `build.sh` / `load.sh` were not run here (no Quartus in WSL). A live USB-UART line `3  ok` is not recorded; `tests/fterm_test.4th` covers the mock backend.

## [0.2.0] - 2026-09-25

### Changed

- **BREAKING** Designs no longer read `FSOC_SOC_TOP`, `FSOC_BLINKY_TOP`, or `FSOC_BLINKY_LED_BIT`. The builder calls `fhdlgen build <design> --out <dir> [--param LED_BIT=n]` (fhdlgen >= 0.5). Leaf copies come from `includes.lst`, not from `awk` on `top.v`.
- Emulation library in `emu/`: `clock` (`Clock`, `env_int` / `env_str`, `FSOC_EMU_CYCLES`), `uart` (`RxShift` / `TxDec`; bit period `-DFSOC_UART_BIT` from `sim.sh`), `script` (`Session`, `EnvLines`, `HostLines`). Task mains live in `fsoc/tasks/` (`blinky_main.cpp`, `soc_main.cpp`, `soc_feed.cpp`).
- **BREAKING** `FSOC_EMU_SNAPSHOT` is gone. SwapForth `include` is flattened in Forth (`soc-flatten`); `Vtop_feed` pulses `dump` and the wrapper writes `firmware.hex` with `$writememh`. `soc_blink` without a scripted line no longer stops on lamp text; set `FSOC_EMU_CYCLES`.
- **BREAKING** The LiteX-style `csr.4th` / `cores.4th` map is gone. One J1 io map in `fsoc/soc/iomap.4th` writes `csr.fs`, `iomap.vh`, and `csr.json`. `lamp.fs` uses `IO-LED` / `IO-TIMER`.
- **BREAKING** `target.4th` manifest: `s" <task>" task:`, `s" <target>" target:`, `s" <board>" board:`, `s" <path>" design:`, `s" <name>" s" <value>" option:`. `fsoc-task!`, `fsoc-target!`, `fsoc-board!`, `fsoc-design!` and `soc-lamp-on` are gone; `soc_blink` uses `s" lamp" s" 1" option:`. `design:` is a path from `FSOC_HOME`.
- Builder core (`fsoc/core.4th`): `paths.4th` (`fsoc-root`, `fsoc-path`, `cwd@`), `sh.4th` (`sh-run`, `sh-cp`, `sh-mkdir`), `log.4th` (`fsoc-note`), `project.4th` (`project%`, manifest words, `project-copy-in`), `registry.4th` (`task-register`, `target-register`), `hdl.4th` (`fhdlgen-build`), `build.4th` (`fsoc-build`: task emit → target emit → target run; `fsoc-load`). Tasks live in `fsoc/tasks/blinky.4th` and `fsoc/tasks/soc.4th` and register themselves; the CLI names no task and no script.
- Targets have `emit` / `run` / `load` hooks. `emulation` copies `emu/con.*` and the task harness (`project.harness$`) and writes `sim.sh`; `quartus` writes `.qsf`, `.sdc`, `build.sh`, `load.sh` with `FAMILY` from the board (`plat-family`; `ep2c5_mini` is `Cyclone II`). `board-load` lives in the core and checks the stack.
- Strings use `fjson.str-*` and `fjson.emit`; lists use `ulist-each`. `fsoc-append`, `fsoc-str-dup`, `fsoc-u>str`, `fsoc-streq`, `pick3`, `blinky-cp` / `soc-cp` and the `../../` path guessing are removed. `csr.json` is written with `fjson.emit-*`.
- Tests run every build in a temporary directory (`tests/fixture.4th`: `TS{`/`test-setup`, `tmp-use-project`, `in-tmp-fsoc`) and end with `expect-stack-clean`; `projects/*` are not touched. New `paths_test`, `sh_test`, `project_test`, `registry_test`, `layers_test`.
- Coverage (`fcov run`): 95% of instrumented definitions (173/182). Uncovered: `fsoc.version`, `fsoc.help`, `fterm`, `fterm-open`, `stty-append`, `fterm-mock`, `sh-rm`, `connector`, `misc`. `fsoc/soc/iomap.4th` is 18/18.

- OpenSpec: `con-term`, `j1-forth`, `soc-emulation`, `soc-io-blink` archived; `soc-build-log` closed, its open tasks moved to `design-out-contract`. Layer changes `builder-hygiene` through `iomap` are implemented (see `doc/roadmap.md`).
- `package.4th`: `fmix ~> 0.8`; dependency `f` and `fcov-exclude tests/golden` dropped. frules installed in `.cursor/rules/`, `fmix hook install --stage all`.

### Removed

- `FSOC_EMU_SNAPSHOT`, C++ `load_forth` / `snapshot_ram` / `top__DOT__` RAM peeks, and the lamp-text oracle in `soc_main`.
- `fsoc/blinky.4th`, `fsoc/soc.4th`, `designs/blinky.4th`, `fsoc/toolchains/quartus.4th`, `tests/load.4th` duplicate include list.
- Dead code: `firmware/ok.4th`, `firmware/j1asm.4th`, `firmware/hex2readmem.4th` (J1 assembler superseded by the SwapForth cross-compiler), `cpu/j1/j1_prompt.v`, `cpu/j1/tb_prompt.v`, `tests/j1_prompt_test.4th`, `fsoc/toolchains/icarus.4th`, `targets/base_soc.4th`, `tests/build/`.
- `firmware/firmware.hex` is no longer tracked; each project writes its own.

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
