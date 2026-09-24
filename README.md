# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.1.1-green.svg)](https://github.com/VitaSound/fsoc)

Forth-native SoC builder: **boards**, **Quartus/Icarus toolchains**, **CSR**, **J1 firmware**, **fterm**. Analogue of LiteX `build` + `soc` on Gforth. Verilog modules come from [fhdlgen](https://github.com/VitaSound/fhdlgen) and [hdl-modules](https://github.com/VitaSound/hdl-modules).

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

## Blinky

Blinky is one task. The leaf is [`rtl/blinky.v`](rtl/blinky.v) (`clk` / `led`, `LED_BIT` defaults to 25). [`designs/blinky_top.4th`](designs/blinky_top.4th) includes that file and instantiates it as `top`. Working solutions (each with its own copies of `top.v` / `blinky.v` and a committed `target.4th`) live under [`projects/`](projects/):

```text
projects/blinky_emul/                  Verilator realtime, LED_BIT=25, console pin events
projects/blinky_vitasound_ep4ce10/     Quartus .qsf
projects/blinky_rz_easyfpga/           Quartus .qsf
```

Run `fsoc` from the project directory. The task and the board are in `target.4th`, not on the command line.

Emulation is Verilator. `fsoc --build` emits the project and runs in realtime (50 MHz wall pace) until Ctrl+C. The console prints one line per event, not per clock: `t=<ns> pin led <value>` when `led` changes (`LED_BIT=25`, ~0.67 s). The same printer is `con_uart` for a future serial decoder (one line per received byte).

```bash
cd projects/blinky_emul
fsoc --build
```

Quartus (`--build` writes the project files and does not run Quartus; the task maps `clk50`→`clk` and `user_led`→`led`). `--load` programs the board. On emulation `--load` does nothing.

```bash
cd projects/blinky_vitasound_ep4ce10
fsoc --build
fsoc --build --load
cd ../blinky_rz_easyfpga
fsoc --build
```

## Minimal SoC

`projects/soc_emul` is a builder task. `fsoc --build` cross-compiles SwapForth J1a, loads `firmware.hex` into the vendored J1 core, and runs Verilator until Ctrl+C. The image is that system's ANS CORE dictionary without `environment?`. On a terminal the session is an ncurses screen: UART text scrolls above, and the bottom row is the host line. Characters, including non-ASCII, appear there as they are typed; Enter sends that line. The reply ends with ` ok`. `FSOC_EMU_CON=log` prints each UART byte as `t=<ns> uart tx <byte>`. `FSOC_EMU_CON=term` forces the text view. A redirected run stays on the byte log unless `term` is set. CSR files (`csr.4th`, `csr.json`) are written in the project directory.

```bash
cd projects/soc_emul
fsoc --build
```

`projects/soc_blink` is the same core with a `'BOOT` word that does not return to the prompt. The loop writes `0` and `1` to `h# 400`. That bit leaves `top` as `led`. The pause is a read of the counter at `h# 800`. The loop also sends `lamp on` and `lamp off` on the UART. A background task and an interrupt controller are a later step, described in [doc/stm8ef-hw.md](doc/stm8ef-hw.md).

`FSOC_EMU_CON` picks the view. `term` writes the UART bytes, so the lamp phrases show as text. `log` prints each UART byte as `t=<ns> uart tx <byte>`. `pin` prints only `t=<ns> pin led 0` and `t=<ns> pin led 1` and does not write the UART bytes. `FSOC_EMU_FAST=1` stops after both lamp phrases.

```bash
cd projects/soc_blink
FSOC_EMU_CON=term FSOC_EMU_FAST=1 fsoc --build
FSOC_EMU_CON=pin FSOC_EMU_FAST=1 fsoc --build
```

`cpu/j1/j1_prompt.v` remains a separate Icarus check of the old UART model.

## Boards

| Board | Device | Notes |
|-------|--------|--------|
| `vitasound_ep4ce10` | EP4CE10E22C8 | pins from VitaPolySimple.qsf |
| `rz_easyfpga` | EP4CE6E22C8 | litex-boards port |
| `ep2c5_mini` | EP2C5T144C8 | Quartus II 13.0sp1 |

## Related

- [MIT ADR-0003](https://github.com/VitaSound/MIT) — Forth-native SoC builder
- [feco](https://github.com/VitaSound/feco) — ecosystem catalog
- [fhdlgen](https://github.com/VitaSound/fhdlgen) — Verilog generator
