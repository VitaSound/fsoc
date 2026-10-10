# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.9.0-green.svg)](https://github.com/VitaSound/fsoc)

English mirror. Russian (canonical for humans): [README.md](README.md).

Forth-native SoC builder: **boards**, **Quartus/Yosys/Verilator**, **iomap**, **firmware**. LiteX-like `build` + `soc` on Gforth. Verilog modules from [fhdlgen](https://github.com/VitaSound/fhdlgen) and [hdl-modules](https://github.com/VitaSound/hdl-modules). Release note (RU): [doc/PRESS-RELEASE-ru.md](doc/PRESS-RELEASE-ru.md).

In the first hour you build a **blinky** under Verilator (`pin led 0` / `1`) and a **Forth console** that answers `3` and `ok`. Boards, other CPUs, and fits come after Day 1. “Two J1 cores” in the press release means profiles **j1a and j1b**, not dual-core; two micro-cores on a bus are [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).

## What you need in the first hour

- Gforth, `fmix packages.get`, `FSOC_HOME` and `PATH` ([feco shell-setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md))
- **Verilator** (canonical path below)
- **Not** needed on day 1: Quartus, Yosys/nextpnr, Proteus, fhdlgen, simavr

Full suite: `fmix test`. Day-1 five terms: [doc/GLOSSARY.md](doc/GLOSSARY.md). After Day 1 (boards, fits, other CPUs): [doc/guide-detail-eng.md](doc/guide-detail-eng.md) — skip it in the first hour.

## Day 1 — start here (FPGA / Verilator)

```bash
git clone git@github.com:VitaSound/fsoc.git
cd fsoc && fmix packages.get
export FSOC_HOME="$PWD"
export PATH="$FSOC_HOME/bin:$PATH"
fsoc version
```

### 1. Blinky (no Forth)

```bash
cd projects/baremetal/blinky_emul && fsoc --build
```

In the log, repeatedly:

```text
t=<ns> pin led 0
t=<ns> pin led 1
```

Stop with Ctrl+C.

### 2. Forth console (`3` and `ok`)

```bash
cd projects/soc/soc_emul
FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .' fsoc --build
```

In the log:

```text
3  ok
```

Git keeps only `target.4th` under each `projects/*`; `fsoc --build` writes the rest in place.

## Three modes

| Mode | In `target.4th` | What you get | Example |
|------|-----------------|--------------|---------|
| Blinky | `blinky` | LED pins, **no** Forth console | `baremetal/blinky_emul` |
| SoC console | `soc` + `sys: fsys` | UART / `ok`, words `+` `.` `:` | `soc/soc_emul` |
| Two micro-cores | `dual-mcpu` | `pin ping` / `pin pong`, **not** fsys | `baremetal/dual_mcpu_emul` |

Later (not Day 1): `soc/soc_atmega8` (MCU HEX), `soc/soc_blink` (lamp on soft-CPU).

## Other paths

### MCU (ATmega8)

```bash
cd projects/baremetal/blinky_atmega && fsoc --build
# Hardware atmega8(avr), firmware.hex

cd ../../soc/soc_atmega8 && fsoc --build
# HEX always; interactive needs simavr + libsimavr-dev:
# ~/fsoc/tools/avr-con ./firmware.hex '1 2 + .'
```

### Two micro-cores (MPSoC)

```bash
cd projects/baremetal/dual_mcpu_emul
FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 fsoc --build
# pin ping 1 and pin pong 1 (each at least twice)
```

Details: [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).

Layers: [doc/MAP-eng.md](doc/MAP-eng.md). CPU profiles: [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).  
Humans: [CONTRIBUTING.md](CONTRIBUTING.md) (RU-first). Agents: [AGENTS.md](AGENTS.md).

## Build shape

Project directory + `target.4th` → `fsoc --build` → artifacts beside the manifest (`sim.sh`, HEX, …). Git keeps only the manifest. Task and board live in the manifest, not the CLI.

Blinky (no `sys:`):

```forth
s" blinky" task:
s" emulation" target:
```

SoC console requires `s" fsys" sys:` or the build stops (`needs fsys`):

```forth
s" soc" task:
s" emulation" target:
s" fsys" sys:
s" lamp" s" 1" option:   \ optional: lamp loop instead of the prompt
```

| Target | `run` |
|--------|-------|
| `emulation` | Verilator (`sim.sh`) |
| `quartus` | project files; `--load` → `load.sh` |
| `yosys` | `build.sh` (nextpnr) |

Boards and fit notes: [doc/guide-detail-eng.md](doc/guide-detail-eng.md) (after Day 1).

## Install (short)

WavePeek is optional (`fmix test` does not call it). Skill: [`.cursor/skills/wavepeek`](.cursor/skills/wavepeek).

`fmix test` includes the fsys console grid [`tests/con_core_test.4th`](tests/con_core_test.4th). One file:

```bash
export FSOC_HOME="$HOME/fsoc"
cd tests && gforth con_core_test.4th
```

## Adding a CPU

New **ISA** → new `cpu:` id and fsys layers. New chip of the same ISA → fasm part file. Fsys console must join `tests/con_core_test.4th`. How-to: [doc/add-cpu-eng.md](doc/add-cpu-eng.md). FMAP axes: [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).

## Related

- [MIT ADR-0003](https://github.com/VitaSound/MIT) · [feco](https://github.com/VitaSound/feco) · [fhdlgen](https://github.com/VitaSound/fhdlgen) · [frules](https://github.com/VitaSound/frules)
