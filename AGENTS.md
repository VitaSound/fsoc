# AGENTS.md — fsoc

Forth-native SoC builder (LiteX analogue) for VitaSound. Host language is **Gforth**. HDL generation for modules lives in [fhdlgen](https://github.com/VitaSound/fhdlgen) >= 0.5 (`fhdlgen build <design> --out <dir>`); this repo is boards, toolchains, iomap, firmware, and tools. Designs do not read the environment.

## Layout

```
fsoc/           IR + DSL + emit
boards/         ep2c5_mini, terasic_de0nano, colorlight_5a_75e_v6_0, colorlight_5a_75e_v7_1, colorlight_5a_75e_v8_2, lfe5u25f_cabga256
designs/        Forth design units (fhdlgen top; leaf RTL stays a .v file; no project dir, board, or launch method)
emu/            Verilator library: con, clock, uart, script, trace (no task names)
rtl/            Pure Verilog (blinky.v, …)
projects/       Working dirs: `baremetal/blinky_*` (no Forth), `soc_*` (Forth). Git: only target.4th; --build emits the rest locally
targets/        emulation (Verilator sim.sh), quartus (project files; no task name)
cpu/j1/         Core kits `j1a/`, `j1b/`, and `j1abs/` (core, stack, memory wrap) plus shared `uart.v`; `j1b/j1b_wrap.v` is the 32-bit cell. `j1abs` is the J1a ISA with bit-serial ROM tables; the wrap stays `j1a/j1_wrap.v`
cpu/mcpu/       Experimental micro-core from https://github.com/cpldcpu/MCPU (GPL-2). Host fasm is `fsys/fasm/mcpu`. Standalone is `projects/standalone_mcpu`. Not a Forth `cpu:` profile.
cpu/cd16/       CD16 core translated from Brad Eckert's VHDL. Profile `cd16` (class 1, MM=D, EX-C=S, CG=F). Host fasm is `fsys/fasm/cd16`. Console is `fsys/kernel/cd16`. Standalone size fit stays `projects/standalone_cd16`. Notes: `doc/cd16.md`.
cpu/msl16/      MSL16 core translated from Philip Leong's 1998 VHDL. Host fasm is `fsys/fasm/msl16`. Standalone is `projects/standalone_msl16` (`ADDR=8`). Profile `msl16` is an fsys console (`ADDR=11`, word hex): `baremetal/blinky_msl16`, `soc_msl16`, `soc_msl16_blink`. Notes: `doc/msl16.md`.
swapforth/      SwapForth image tool, moved intact: `j1a/`, `j1b/`, `common/`
fsys/fasm/      Host assembler for j1a, j1b, avr, bcpu, mcpu, cd16, and msl16: comma words, labels, `[asm]`/`[endasm]`. avr writes Intel HEX. bcpu writes 16-bit words. mcpu writes 64 instruction bytes and is not a Forth image. Part files `atmega8`, `atmega328p`, `atmega2560` hold flash, SRAM, EEPROM, and register addresses. Kernel console stays in `fsys/kernel/<cpu>`; fasm-only blink is `firmware/blink_avr.4th` and `firmware/blink_bcpu.4th`
fsoc/cpu.4th    Forth profiles (`j1a`, `j1b`, `j1abs`, `stm8`, `z80`, `avr`, `bcpu`, `cd16`). Manifest `cpu:`; empty on task `soc` is `j1a`. A new ISA is a new id here (FMAP + CG). A new chip of an existing ISA is a part file under `fsys/fasm/<id>/`, not a new id. `j1abs` is the same ISA as `j1a` (class 0, CG=I) with `cpu-port` `j1a`: bit-serial ALU and control tables, no kernel of its own, no `con_core` row. The short console check is `tests/j1abs_test.4th`. The full j1a word script is `tests/j1abs_words.4th` and is not part of `fmix`. Failures already solved (one-shot blink, UART start bit, cycle cap, mixed Verilator) are in `.cursor/rules/j1abs-core.mdc`. `bcpu` is fasm plus an fsys console (`s" fsys" sys:` loads `fsys/kernel/bcpu`; `bit.hex` is kept for attribution and is not the soc image). The console is a row in `tests/con_core_test.4th`. How to add a platform: `.cursor/rules/fsoc-cpu-target.mdc`
fsoc/sys.4th    Image tool named by `sys:`. Empty is `swapforth`. `fsys` assembles `fsys/kernel/<cpu>`, then the host compiles `fsys/common` (j1b then `fsys/j1b/extra.4th`; j1a with `extra-min=1` then `fsys/j1a/extra-min.4th`; `avr` console then `fsys/avr/extra-min.4th`; `avr` with `blink=1` then `fsys/avr/extra.4th`). `s" image" s" release" option:` with an application option such as `lamp` or `blink` loads only the closure of those programs plus `fsys/<cpu>/release.4th`; otherwise the full layers are loaded. The dictionary JSON is `doc/j1-word-graph/<cpu-sys>.json`. Profile `avr` is class 1 Harvard STC (EX-C=S, CG=F): empty `sys:` stops; `s" fsys" sys:` assembles `fsys/kernel/avr`, host `avr-cross` adds extra-min (console) or extra (blink), then Intel HEX. `s" blink" s" 1" option:` with `s" image" s" release" option:` appends `firmware/blink.fs`. Kernel is the console; the app stays in `firmware/`. `soc.4th` names no cpu id; the CG emitter branches. Profile `bcpu` is class 0 accumulator (EX-C=B, CG=F): empty `sys:` stops; `s" fsys" sys:` assembles `fsys/kernel/bcpu`, host `bcpu-cross` adds extra-min, then word hex. `s" blink" s" 1" option:` compiles `firmware/bcpu_blink.fs` and starts it from boot. The terminal shows UART text (`blink on` / `blink off`); `FSOC_EMU_CON=pin` shows only the pin. Failures already solved (words hang, colon literals, RX queue, `con_core`, kit-less blinky) are in `.cursor/rules/bcpu-console.mdc`. Profile `cd16` is class 1 Harvard STC (EX-C=S, CG=F): empty `sys:` stops; `s" fsys" sys:` assembles `fsys/kernel/cd16`, host `cd16-cross` adds extra-min, then word hex. `s" blink" s" 1" option:` compiles `firmware/cd16_blink.fs` and starts it from boot. The console is a row in `tests/con_core_test.4th`. Baremetal blink is `firmware/blink_cd16.4th`. The chained call script is `tests/cd16_words.4th` and is not part of `fmix`.

fsoc/kit.4th    Core kit: file names, cell width, stack depths, RAM words. The kit does not name the image tool
fsoc/compare.4th One scenario, several `cpu:` rows: cell width, image bytes, Verilator cycles. No synthesis. A row stays empty when that profile cannot build an image
firmware/       lamp.fs (J1 lamp loop), blink.fs (AVR Forth on kernel), blink_avr.4th (fasm blink), midi_foot.4th (host mock, stub)
tools/          fterm.4th line terminal (device path, or mock without a path); avr-con simavr UART console for ATmega8 HEX; peek.sh queries trace.vcd with WavePeek
```

Blinky (no Forth) lives under `projects/baremetal/`. HDL copies omit `cpu:`. AVR is the same task `blinky` with `s" avr" cpu:` (`projects/baremetal/blinky_atmega`, PB0 via `firmware/blink_avr.4th`). `soc_emul` runs SwapForth J1a: on a tty the session is text and the reply ends with ` ok`; `FSOC_EMU_CON=log` keeps the byte log. `soc_emul_colorlight_5a_75e_v6_0` is that console at the Colorlight 25 MHz clock; UART stays in the simulator. Firmware is written by `Vtop_feed` (`dump` → `$writememh`), not by a C++ RAM snapshot. `soc_blink` runs a `'BOOT` loop that stores `0` and `1` at `IO-LED` and waits on `IO-TIMER` (`csr.fs`). `FSOC_EMU_CON=term` shows the lamp text, `FSOC_EMU_CON=pin` shows only `pin led` `0` and `1`. A short lamp run uses `FSOC_EMU_CYCLES` (tests use 800000). Background and an interrupt controller stay a later step in `doc/stm8ef-hw.md`. Each project dir is a working copy: git has only `target.4th` (`s" <task>" task:`, `s" <target>" target:`, `s" <board>" board:`, `s" <path>" design:`, `s" <id>" cpu:`, `s" <id>" model:`, `s" <id>" sys:`, `s" <name>" s" <value>" option:`). ATmega projects MUST set `s" atmega8" model:` (or another part id). Empty `model:` on `cpu: avr` falls back to `cpu-ref`. `--build` writes leaves, `top.v`, firmware, and scripts there; they must not be committed. Debug task and design on `emulation`; a board project reuses the same design with `quartus` + `board:`. Run `fsoc --build` from that directory: task emit → target emit → target run; `--load` → target load. `--clean` deletes that output and keeps `target.4th`. Tasks register with `task-register`, targets with `target-register`; the CLI knows no task name. Repository files are resolved only from `FSOC_HOME` (`fsoc-path`); nothing guesses `../../`. Tests build in temporary directories (`tests/fixture.4th`) and never write into `projects/*`. `always` is not generated from Forth strings.
## Commands

```bash
fmix packages.get
fmix test                # full suite, including the long core tests
# pre-push (tools/pre-push.sh) runs the short files always. The long suites
# (con_core, common, j1abs, bcpu, avr dict/words/con/pin/blink) run only when
# the push touches that core. avr_con_test needs simavr + libsimavr-dev.
# one file: cd tests && FSOC_HOME=$FSOC_HOME gforth con_core_test.4th
fsoc version             # needs FSOC_HOME + PATH (see feco shell-setup)
cd projects/baremetal/blinky_emul && fsoc --build
cd projects/baremetal/blinky_atmega && fsoc --build
cd projects/soc_emul && fsoc --build
cd projects/soc_emul_colorlight_5a_75e_v6_0 && fsoc --build
cd projects/soc_terasic_de0nano && fsoc --build
cd projects/soc_blink_colorlight_5a_75e_v6_0 && fsoc --build
cd projects/baremetal/blinky_terasic_de0nano && fsoc --build
```

Quartus is optional (often missing in WSL). Verilator covers blinky and the SwapForth session; Icarus covers the rtl/ testbenches.

## Process

Non-trivial changes: OpenSpec in `openspec/`. Before commit: `fmix test`, `flint`, `fcov`.

A value the build shows or uses comes from the project: a file it copies, generates, cross-compiles, or feeds. If that source is not found, do not hardcode a stand-in list or name. Stop and ask where the data comes from and how to use it.

## New CPU / MCU

A new ISA is a new `cpu:` id (FMAP + CG) with the same fsys layers as j1a/j1b/avr: `fsys/fasm/<id>/` → `fsys/kernel/<id>/` (Forth console, not blink) → `fsys/host/<id>-cross.4th` → `fsys/<id>/extra.4th` → `firmware/*.fs`. A new chip of an existing ISA is only a part file under fasm. Empty `sys:` is swapforth; an MCU without SwapForth requires `s" fsys" sys:`. Branch by CG in the existing emitter, not by a cpu id literal in `soc.4th`. Baremetal LED is task `blinky` plus `cpu:`, fasm is the assembler. AVR `--build` prints Hardware `atmega8(avr)` then Software `firmware.hex: N bytes of flash`.

A new **fsys console** id MUST join `tests/con_core_test.4th`: manifest in `tests/con_session.4th`, JSON via `doc/j1-word-graph/build.py`, every name tagged in `tests/con_words.py`, BS/DEL in that kernel `accept`. Keep id-only words out of the shared script (`tests/avr_con_test.4th` is the AVR-only slice). A new chip of an existing ISA does not add a `con_core` row. Run `fmix test` or `cd tests && FSOC_HOME=<root> gforth con_core_test.4th`. Agent rule: `.cursor/rules/fsoc-cpu-target.mdc`. Skill: `add-cpu-target`. Specs: `openspec/specs/forth-cross/spec.md`, `openspec/specs/fsys/spec.md`.

Before review of a new `cpu:` or a new body of the same ISA, the last step is three emulation sessions (spec: forth-cross, «три сеанса»). Baremetal blink and soc blink, `FSOC_EMU_CON=pin` and `FSOC_EMU_EDGES=4`, each show `pin led 0` and `pin led 1` at least twice. Soc with `s" fsys" sys:` answers `words` and at least two expressions (`1 2 + .` → `3  ok`, plus `:` or `.s`). That sum is the hand launch: do not export `FSOC_EMU_UART_GAP`. The panel buffers the line and Enter is `push_line`; the profile gap is what `sim.sh` applies when the variable is unset. A script that exports the gap is not this check. A new kernel runs its `con_core` row. A port runs the word script that is not part of `fmix` (`gforth tests/j1abs_words.4th`). A short `1 2 + .` and one LED edge are not this step.
