# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.1.0-green.svg)](https://github.com/VitaSound/fsoc)

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

CSR export stays a library word (`csr-export-4th`, `csr-export-json` into `build/soc/software`). There is no builder command for it.

J1 simulation prints a Forth `ok` prompt (`cpu/j1/tb_prompt.v`).

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
