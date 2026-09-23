# AGENTS.md — fsoc

Forth-native SoC builder (LiteX analogue) for VitaSound. Host language is **Gforth**. HDL generation for modules lives in [fhdlgen](https://github.com/VitaSound/fhdlgen); this repo is boards, toolchains, CSR, firmware, and tools.

## Layout

```
fsoc/           IR + DSL + emit
boards/         vitasound_ep4ce10, rz_easyfpga, ep2c5_mini
designs/        Forth design units (fhdlgen top; leaf RTL stays a .v file; no project dir, board, or launch method)
emu/            Verilator console: con_pin (level changes), con_uart (decoded bytes)
rtl/            Pure Verilog (blinky.v, …)
projects/       Working solutions (blinky_emul, blinky_<board>, soc_emul, …)
targets/        emulation (Verilator sim.sh), quartus (project files; no task name)
cpu/j1/         J1 core and UART from swapforth, wrapper, prompt model, LICENSE
firmware/       J1 Forth assembler, ok image, hex2readmem, FOOTSWITCH-SCAN
tools/fterm.4th line terminal (wait for ok)
```

Blinky is one task (`rtl/blinky.v` + fhdlgen `top`; emulation `main` is `fsoc/blinky_main.cpp`, not a file in `emu/`). Working solutions live under `projects/`: `blinky_emul` (Verilator realtime until Ctrl+C; `emu/con` prints `t=<ns> pin led <value>` on change; `con_uart` for a decoded serial byte), `blinky_vitasound_ep4ce10` and `blinky_rz_easyfpga` (Quartus `.qsf`, default `LED_BIT` 25). `soc_emul` runs a J1 image assembled from Forth; executing it prints `ok` on `con_uart`. The next step is a full Forth system on that core. Each project dir has its own copies of the leaf and a `target.4th` (task, target, board). Run `fsoc --build` from that directory. `always` is not generated from Forth strings.
## Commands

```bash
fmix packages.get
fmix test
fsoc version             # needs FSOC_HOME + PATH (see feco shell-setup)
cd projects/blinky_emul && fsoc --build
cd projects/soc_emul && fsoc --build
cd projects/blinky_rz_easyfpga && fsoc --build
```

Quartus is optional (often missing in WSL). Icarus covers blinky and the J1 prompt.

## Process

Non-trivial changes: OpenSpec in `openspec/`. Before commit: `fmix test`, `flint`, `fcov`.
