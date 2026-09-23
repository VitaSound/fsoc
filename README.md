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

```bash
fsoc blinky
# or: gforth targets/blinky.4th
iverilog -o tb build/blinky/blinky.v build/blinky/tb.v && vvp tb
# Quartus project: build/blinky/blinky.qsf (needs Quartus Prime Lite)
```

## Minimal SoC

```bash
fsoc soc
# software/csr.4th and csr.json in build/soc/software
```

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
