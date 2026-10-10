# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.9.0-green.svg)](https://github.com/VitaSound/fsoc)

English mirror. Russian (canonical for humans): [README.md](README.md).

Forth-native SoC builder: **boards**, **Quartus/Yosys/Verilator**, **iomap**, **firmware**. LiteX-like `build` + `soc` on Gforth. Verilog modules from [fhdlgen](https://github.com/VitaSound/fhdlgen) and [hdl-modules](https://github.com/VitaSound/hdl-modules). Release note (RU): [doc/PRESS-RELEASE-ru.md](doc/PRESS-RELEASE-ru.md).

One canvas: soft-CPU on FPGA, MCU (ATmega8), and a **dual micro-core** ping-pong demo. “Two J1 cores” in the press release means profiles **j1a and j1b**, not dual-core; MPSoC is [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).

## What you need in the first hour

- Gforth, `fmix packages.get`, `FSOC_HOME` and `PATH` ([feco shell-setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md))
- FPGA path: **Verilator**
- MCU path: HEX always; interactive needs **simavr** + `libsimavr-dev` (otherwise console skips)
- **Not** needed on day 1: Quartus, Yosys/nextpnr, Proteus, fhdlgen

Full suite: `fmix test`. Long guide: [doc/guide-detail-eng.md](doc/guide-detail-eng.md). Human entry is Russian-first ([README.md](README.md), [CONTRIBUTING.md](CONTRIBUTING.md)).

## Day 1

```bash
git clone git@github.com:VitaSound/fsoc.git
cd fsoc && fmix packages.get
export FSOC_HOME="$PWD"
export PATH="$FSOC_HOME/bin:$PATH"
fsoc version
```

### FPGA / soft-CPU (Verilator)

```bash
cd projects/baremetal/blinky_emul && fsoc --build
# pin led 0 / 1

cd ../soc_emul
FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .' fsoc --build
# 3 and ok
```

### MCU (ATmega8)

```bash
cd projects/baremetal/blinky_atmega && fsoc --build
cd ../../soc_atmega8 && fsoc --build
# optional: ~/fsoc/tools/avr-con ./firmware.hex '1 2 + .'
```

### Two micro-cores (MPSoC)

```bash
cd projects/baremetal/dual_mcpu_emul
FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 fsoc --build
# pin ping 1 and pin pong 1 (each at least twice)
```

Terms: [doc/GLOSSARY.md](doc/GLOSSARY.md). Layers: [doc/MAP.md](doc/MAP.md). CPU / FMAP: [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).  
Humans: [CONTRIBUTING.md](CONTRIBUTING.md). Agents: [AGENTS.md](AGENTS.md).

## Build shape

Git keeps only `target.4th` per project. `fsoc --build` emits the rest. Details, boards, fits: [doc/guide-detail-eng.md](doc/guide-detail-eng.md).

## Adding a CPU

New **ISA** → new `cpu:` id and fsys layers ([`.cursor/rules/fsoc-cpu-target.mdc`](.cursor/rules/fsoc-cpu-target.mdc)). New chip of the same ISA → fasm part file. Fsys console must join `tests/con_core_test.4th`.

## Related

- [MIT ADR-0003](https://github.com/VitaSound/MIT) · [feco](https://github.com/VitaSound/feco) · [fhdlgen](https://github.com/VitaSound/fhdlgen) · [frules](https://github.com/VitaSound/frules)
