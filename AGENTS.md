# AGENTS.md — fsoc

Forth-native SoC builder (LiteX analogue) for VitaSound. Host language is **Gforth**. HDL generation for modules lives in [fhdlgen](https://github.com/VitaSound/fhdlgen) >= 0.5 (`fhdlgen build <design> --out <dir>`); this repo is boards, toolchains, iomap, firmware, and tools. Designs do not read the environment.

## Layout

```
fsoc/           IR + DSL + emit
boards/         vitasound_ep4ce10, rz_easyfpga, ep2c5_mini, terasic_de0nano
designs/        Forth design units (fhdlgen top; leaf RTL stays a .v file; no project dir, board, or launch method)
emu/            Verilator library: con, clock, uart, script, trace (no task names)
rtl/            Pure Verilog (blinky.v, …)
projects/       Working dirs (blinky_emul, blinky_<board>, soc_emul, …). Git: only target.4th; --build emits the rest locally
targets/        emulation (Verilator sim.sh), quartus (project files; no task name)
cpu/j1/         J1 core and UART from swapforth, wrapper, LICENSE
firmware/       lamp.fs (J1 lamp loop), midi_foot.4th (host mock, stub)
tools/          fterm.4th line terminal (device path, or mock without a path); peek.sh queries trace.vcd with WavePeek
```

Blinky is one task (`rtl/blinky.v` + fhdlgen `top`; emulation `main` is `fsoc/tasks/blinky_main.cpp`, not a file in `emu/`). Working solutions live under `projects/`: `blinky_emul` (Verilator realtime until Ctrl+C; `emu/con` prints `t=<ns> pin led <value>` on change; `con_uart` for a decoded serial byte; `FSOC_EMU_TRACE=1` at `--build` writes `trace.vcd`, 4096 cycles or `FSOC_EMU_CYCLES` if longer, then `"$FSOC_HOME/tools/peek.sh"`; skill `.cursor/skills/wavepeek`), `blinky_vitasound_ep4ce10` and `blinky_rz_easyfpga` (Quartus `.qsf`, default `LED_BIT` 25). `soc_emul` runs SwapForth J1a: on a tty the session is text and the reply ends with ` ok`; `FSOC_EMU_CON=log` keeps the byte log. `soc_emul_colorlight_5a_75e_v6_0` is that console at the Colorlight 25 MHz clock; UART stays in the simulator. Firmware is written by `Vtop_feed` (`dump` → `$writememh`), not by a C++ RAM snapshot. `soc_blink` runs a `'BOOT` loop that stores `0` and `1` at `IO-LED` and waits on `IO-TIMER` (`csr.fs`). `FSOC_EMU_CON=term` shows the lamp text, `FSOC_EMU_CON=pin` shows only `pin led` `0` and `1`. A short lamp run uses `FSOC_EMU_CYCLES` (tests use 800000). Background and an interrupt controller stay a later step in `doc/stm8ef-hw.md`. Each project dir is a working copy: git has only `target.4th` (`s" <task>" task:`, `s" <target>" target:`, `s" <board>" board:`, `s" <path>" design:`, `s" <name>" s" <value>" option:`). `--build` writes leaves, `top.v`, firmware, and scripts there; they must not be committed. Debug task and design on `emulation`; a board project reuses the same design with `quartus` + `board:`. Run `fsoc --build` from that directory: task emit → target emit → target run; `--load` → target load. `--clean` deletes that output and keeps `target.4th`. Tasks register with `task-register`, targets with `target-register`; the CLI knows no task name. Repository files are resolved only from `FSOC_HOME` (`fsoc-path`); nothing guesses `../../`. Tests build in temporary directories (`tests/fixture.4th`) and never write into `projects/*`. `always` is not generated from Forth strings.
## Commands

```bash
fmix packages.get
fmix test
fsoc version             # needs FSOC_HOME + PATH (see feco shell-setup)
cd projects/blinky_emul && fsoc --build
cd projects/soc_emul && fsoc --build
cd projects/soc_emul_colorlight_5a_75e_v6_0 && fsoc --build
cd projects/soc_vitasound_ep4ce10 && fsoc --build
cd projects/soc_blink_colorlight_5a_75e_v6_0 && fsoc --build
cd projects/blinky_rz_easyfpga && fsoc --build
```

Quartus is optional (often missing in WSL). Verilator covers blinky and the SwapForth session; Icarus covers the rtl/ testbenches.

## Process

Non-trivial changes: OpenSpec in `openspec/`. Before commit: `fmix test`, `flint`, `fcov`.

A value the build shows or uses comes from the project: a file it copies, generates, cross-compiles, or feeds. If that source is not found, do not hardcode a stand-in list or name. Stop and ask where the data comes from and how to use it.
