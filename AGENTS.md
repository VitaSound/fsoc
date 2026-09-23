# AGENTS.md — fsoc

Forth-native SoC builder (LiteX analogue) for VitaSound. Host language is **Gforth**. HDL generation for modules lives in [fhdlgen](https://github.com/VitaSound/fhdlgen); this repo is boards, toolchains, CSR, firmware, and tools.

## Layout

```
fsoc/           IR + DSL + emit
boards/         vitasound_ep4ce10, rz_easyfpga, ep2c5_mini
designs/        Forth design units (fhdlgen top; leaf RTL stays a .v file)
emu/            Verilator console: con_pin (level changes), con_uart (decoded bytes)
rtl/            Pure Verilog (blinky.v, …)
targets/        emulation, quartus (base_soc is still a bundled SoC script)
cpu/j1/         J1a wrapper, prompt UART model, LICENSE
firmware/       csr HAL export, hex2readmem, FOOTSWITCH-SCAN
tools/fterm.4th line terminal (wait for ok)
```

Blinky is one task (`rtl/blinky.v` + fhdlgen `top`). Builds: `build/blinky/emulation` (Verilator realtime until Ctrl+C; `emu/con` prints `t=<ns> pin led <value>` on change; `con_uart` for a future decoded serial byte), `build/blinky/vitasound_ep4ce10` and `build/blinky/rz_easyfpga` (Quartus `.qsf`, default `LED_BIT` 25). `targets/quartus.4th` takes the board name. `always` is not generated from Forth strings.
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
