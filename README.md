# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.3.0-green.svg)](https://github.com/VitaSound/fsoc)

Forth-native SoC builder: **boards**, **Quartus/Verilator toolchains**, **iomap**, **J1 firmware**. Analogue of LiteX `build` + `soc` on Gforth. Verilog modules come from [fhdlgen](https://github.com/VitaSound/fhdlgen) and [hdl-modules](https://github.com/VitaSound/hdl-modules).

## Install

```bash
git clone git@github.com:VitaSound/fsoc.git
cd fsoc && fmix packages.get
fmix test
```

Shell (see [feco shell-setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md)):

```bash
export FSOC_HOME="$HOME/fsoc"
export PATH="$FSOC_HOME/bin:$PATH"
fsoc version
```

[WavePeek](https://kleverhq.github.io/wavepeek/) is optional. `fmix test` does not call it. It answers questions about a `trace.vcd` from emulation. The install script from that site puts `wavepeek` in `~/.local/bin`; that directory must be on `PATH` (a login shell picks it up from `~/.profile`).

```bash
curl --proto '=https' --tlsv1.2 -LsSf https://kleverhq.github.io/wavepeek/install.sh | sh
wavepeek --version
```

The agent skill in this repo is [`.cursor/skills/wavepeek`](.cursor/skills/wavepeek) (pin 3.0.1). Refresh it from the same binary:

```bash
wavepeek skill .cursor/skills/wavepeek
```

## Blinky

Blinky is one task. The leaf is [`rtl/blinky.v`](rtl/blinky.v) (`clk` / `led`, `LED_BIT` defaults to 25). [`designs/blinky_top.4th`](designs/blinky_top.4th) includes that file and instantiates it as `top`. Working solutions live under [`projects/`](projects/). **Git tracks only `target.4th` in each directory.** `fsoc --build` emits the rest (`top.v`, leaf copies, `firmware.hex`, `sim.sh` / `.qsf`, `obj_dir`, …) into that directory; `.gitignore` keeps those files out. After a clone, `projects/soc_blink/` is the manifest alone.

Debug the task and the design in an `emulation` project (`blinky_emul`, `soc_emul`, `soc_blink`). A board project is the same task and design with `quartus` and `board:` — not a second HDL tree.

```text
projects/blinky_emul/                  Verilator realtime, LED_BIT=25, console pin events
projects/blinky_vitasound_ep4ce10/     Quartus .qsf
projects/blinky_rz_easyfpga/           Quartus .qsf
```

Run `fsoc` from the project directory. The task and the board are in `target.4th`, not on the command line:

```forth
s" blinky" task:            \ registered task (fsoc/tasks/)
s" quartus" target:         \ emulation | quartus
s" rz_easyfpga" board:      \ boards/<name>.4th; omit for emulation
s" designs/soc_top.4th" design:   \ fhdlgen top, path from FSOC_HOME (soc only)
s" lamp" s" 1" option:      \ task option
```

`--build` runs the task's emit, then the target's `emit` and `run`; `--load` runs the target's `load`. Every repository file (`rtl/`, `cpu/`, `emu/`, `designs/`, `boards/`) is found through `FSOC_HOME`; the project directory is the current directory.

| Target | `emit` | `run` | `load` |
|--------|--------|-------|--------|
| `emulation` | `emu/{con,clock,uart,script,trace}.*`, task harness, `sim.sh` | `sh sim.sh` until Ctrl+C or `FSOC_EMU_CYCLES` | nothing |
| `quartus` | `<project>.qsf`, `.sdc`, `build.sh`, `load.sh` | nothing | `sh load.sh` |

Emulation is Verilator. `fsoc --build` emits the project and runs in realtime (50 MHz wall pace) until Ctrl+C. The console prints one line per event, not per clock: `t=<ns> pin led <value>` when `led` changes (`LED_BIT=25`, ~0.67 s). The same printer is `con_uart` for a future serial decoder (one line per received byte).

```bash
cd projects/blinky_emul
fsoc --build
```

`FSOC_EMU_TRACE=1` on that `--build` compiles the viewer with Verilator `--trace` and writes `trace.vcd` (4096 cycles, or `FSOC_EMU_CYCLES` when that limit is longer). The run then continues until its usual stop. From the project directory, `"$FSOC_HOME/tools/peek.sh" info` sends that file to WavePeek. Install the binary as in [Install](#install).

Quartus (`--build` writes the project files and does not run Quartus; the task maps `clk50`→`clk` and `user_led`→`led`). `--load` programs the board. On emulation `--load` does nothing.

```bash
cd projects/blinky_vitasound_ep4ce10
fsoc --build
fsoc --build --load
cd ../blinky_rz_easyfpga
fsoc --build
```

## Minimal SoC

`projects/soc_emul` is a builder task. `fsoc --build` cross-compiles SwapForth J1a, loads `firmware.hex` into the vendored J1 core, and runs Verilator until Ctrl+C. The image is that system's ANS CORE dictionary without `environment?`. On a terminal the session is an ncurses screen: UART text scrolls above, and the bottom row is the host line. Characters, including non-ASCII, appear there as they are typed; Enter sends that line. The reply ends with ` ok`. `FSOC_EMU_CON=log` prints each UART byte as `t=<ns> uart tx <byte>`. `FSOC_EMU_CON=term` forces the text view. A redirected run stays on the byte log unless `term` is set. The io map is written as `csr.fs` (SwapForth constants `IO-LED` …), `iomap.vh` (wrapper `localparam`s), and `csr.json` (`bus` `j1-io`).

```bash
cd projects/soc_emul
fsoc --build
```

`projects/soc_blink` is the same core with a `'BOOT` word that does not return to the prompt. The loop writes `0` and `1` to `IO-LED`. That bit leaves `top` as `led`. The pause is a read of `IO-TIMER`. The loop also sends `lamp on` and `lamp off` on the UART. A background task and an interrupt controller are a later step, described in [doc/stm8ef-hw.md](doc/stm8ef-hw.md).

`FSOC_EMU_CON` picks the view. `term` writes the UART bytes, so the lamp phrases show as text. `log` prints each UART byte as `t=<ns> uart tx <byte>`. `pin` prints only `t=<ns> pin led 0` and `t=<ns> pin led 1` and does not write the UART bytes. A run without a scripted UART line ends at Ctrl+C or `FSOC_EMU_CYCLES`. Tests use `FSOC_EMU_CYCLES=800000` with `FSOC_EMU_FAST=1`.

```bash
cd projects/soc_blink
FSOC_EMU_CON=term FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=800000 fsoc --build
FSOC_EMU_CON=pin FSOC_EMU_FAST=1 FSOC_EMU_CYCLES=800000 fsoc --build
```

## SoC on a board

`projects/soc_vitasound_ep4ce10` writes Quartus files and `firmware.hex`. `--build` does not run Quartus. `--load` runs `load.sh`. Then a host line on the USB UART:

```bash
cd projects/soc_vitasound_ep4ce10
fsoc --build --load
gforth tools/fterm.4th /dev/ttyUSB0
```

`fterm` without a path still answers `ok` from memory.

`tools/fterm.4th` and `firmware/midi_foot.4th`: `fterm` talks to a real port when given a path; `midi_foot` is a host mock of FOOTSWITCH-SCAN.

## Boards

| Board | Device | Notes | serial |
|-------|--------|--------|--------|
| `vitasound_ep4ce10` | EP4CE10E22C8 | pins from VitaPolySimple.qsf | tx 114 / rx 115 |
| `rz_easyfpga` | EP4CE6E22C8 | litex-boards port | tx 114 / rx 115 |
| `ep2c5_mini` | EP2C5T144C8 | Quartus II 13.0sp1 | — |

## Related

- [MIT ADR-0003](https://github.com/VitaSound/MIT) — Forth-native SoC builder
- [feco](https://github.com/VitaSound/feco) — ecosystem catalog
- [fhdlgen](https://github.com/VitaSound/fhdlgen) >= 0.5 — Verilog generator (`fhdlgen build <design> --out <dir>`)
