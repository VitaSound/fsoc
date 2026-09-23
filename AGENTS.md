# AGENTS.md — fsoc

Forth-native SoC builder (LiteX analogue) for VitaSound. Host language is **Gforth**. HDL generation for modules lives in [fhdlgen](https://github.com/VitaSound/fhdlgen); this repo is boards, toolchains, CSR, firmware, and tools.

## Layout

```
fsoc/           IR + DSL + emit
boards/         vitasound_ep4ce10, rz_easyfpga, ep2c5_mini
designs/        Forth design units (path to RTL files; no Verilog body strings)
rtl/            Pure Verilog (blinky.v, …)
targets/        blinky, base_soc
cpu/j1/         J1a wrapper, prompt UART model, LICENSE
firmware/       csr HAL export, hex2readmem, FOOTSWITCH-SCAN
tools/fterm.4th line terminal (wait for ok)
```

Blinky (path 2): logic in `rtl/blinky.v`; `designs/blinky.4th` + targets only wire board/toolchain. Full Forth generation of `always` (path 1) waits on fhdlgen expr-AST.
## Commands

```bash
fmix packages.get
fmix test
fsoc version             # needs FSOC_HOME + PATH (see feco shell-setup)
fsoc blinky
fsoc soc
```

Quartus is optional (often missing in WSL). Icarus covers blinky and the J1 prompt.

## Process

Non-trivial changes: OpenSpec in `openspec/`. Before commit: `fmix test`, `flint`, `fcov`.
