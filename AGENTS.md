# AGENTS.md — fsoc

Forth-native SoC builder (LiteX analogue) for VitaSound. Host language is **Gforth**. HDL generation for modules lives in [fhdlgen](https://github.com/VitaSound/fhdlgen); this repo is boards, toolchains, CSR, firmware, and tools.

## Layout

```
fsoc/           IR + DSL + emit
boards/         vitasound_ep4ce10, rz_easyfpga, ep2c5_mini
designs/        Forth design units (fhdlgen top; leaf RTL stays a .v file; no project dir, board, or launch method)
emu/            Verilator console: con_pin (level changes), con_uart (log or terminal bytes)
rtl/            Pure Verilog (blinky.v, …)
projects/       Working solutions (blinky_emul, blinky_<board>, soc_emul, …)
targets/        emulation (Verilator sim.sh), quartus (project files; no task name)
cpu/j1/         J1 core and UART from swapforth, wrapper, prompt model, LICENSE
firmware/       J1 Forth assembler, hex2readmem, FOOTSWITCH-SCAN
tools/fterm.4th line terminal (wait for ok)
```

Blinky is one task (`rtl/blinky.v` + fhdlgen `top`; emulation `main` is `fsoc/blinky_main.cpp`, not a file in `emu/`). Working solutions live under `projects/`: `blinky_emul` (Verilator realtime until Ctrl+C; `emu/con` prints `t=<ns> pin led <value>` on change; `con_uart` for a decoded serial byte), `blinky_vitasound_ep4ce10` and `blinky_rz_easyfpga` (Quartus `.qsf`, default `LED_BIT` 25). `soc_emul` runs SwapForth J1a: on a tty the session is text and the reply ends with ` ok`; `FSOC_EMU_CON=log` keeps the byte log. `soc_blink` runs a `'BOOT` loop that stores `0` and `1` at `h# 400` and waits on the counter at `h# 800`. `FSOC_EMU_CON=term` shows the lamp text, `FSOC_EMU_CON=pin` shows only `pin led` `0` and `1`. Background and an interrupt controller stay a later step in `doc/stm8ef-hw.md`. Each project dir has its own copies of the leaf and a `target.4th` (task, target, board). Run `fsoc --build` from that directory. `always` is not generated from Forth strings.
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

A value the build shows or uses comes from the project: a file it copies, generates, cross-compiles, or feeds. If that source is not found, do not hardcode a stand-in list or name. Stop and ask where the data comes from and how to use it.
