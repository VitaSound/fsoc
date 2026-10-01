---
name: add-cpu-target
description: Adds a new fsoc CPU or MCU platform using the same fsys layers as j1a/j1b/avr (profile, fasm, kernel console, host cross, extra, firmware). Use when the user asks to add a processor, port Forth to an MCU, create a new cpu: id, or extend stm8/z80/avr-style targets.
---

# Add an fsoc CPU / MCU target

Follow `.cursor/rules/fsoc-cpu-target.mdc` and the specs `openspec/specs/forth-cross/spec.md`, `openspec/specs/fsys/spec.md`. Classify with `forth-system-context` (FMAP class, MM, EX-C, CG) before writing files.

## Checklist

1. **Id vs chip** — new ISA → `cpu-new` in `fsoc/cpu.4th`. Same ISA, other package → `fsys/fasm/<id>/<part>.4th` only.
2. **CG path** — register or extend the emitter for that CG. Do not add the id as a literal in `fsoc/tasks/soc.4th`.
3. **sys:** — empty is swapforth. If this id has no SwapForth tree, require `s" fsys" sys:` and abort otherwise.
4. **Layers** — `fsys/fasm/<id>/` → `fsys/kernel/<id>/kernel.4th` (console) → `fsys/host/<id>-cross.4th` → `fsys/<id>/extra.4th` → optional `firmware/*.fs`.
5. **Kernel** — UART console, `quit`, `words`, `:`. Application I/O stays in `firmware/` behind an option, like `lamp` / `blink`. Baremetal LED is task `blinky` plus `cpu:`, not a task named `fasm`.
6. **Tests** — host dictionary names, HEX/EOF or the CG-E stop; `fcov` on each new fsys directory ≥ 90%. `soc.4th` still has no cpu id literals. AVR log has `Hardware` `atmega8(avr)` and `firmware.hex: N bytes of` flash.
7. **Console grid** — if this id has an fsys kernel console, extend `tests/con_session.4th` + `tests/con_core_test.4th`, add `doc/j1-word-graph/fsys-<id>*.json` via `build.py`, tag every name in `tests/con_words.py`, and implement BS/DEL in that `accept`. Id-only words go in a new or existing `*_test.4th`, not a copy of the shared REPL. A chip part file does not add a `con_core` row. Verify: `cd tests && FSOC_HOME=<root> gforth con_core_test.4th` (and `fmix test`). Specs: `openspec/specs/fsys/spec.md`, `openspec/specs/forth-cross/spec.md`.
8. **Docs** — `AGENTS.md` layout line for that id; OpenSpec delta if the profile or CG behaviour changes.
9. **Failures already solved** — read `.cursor/rules/j1abs-core.mdc` and `.cursor/rules/bcpu-console.mdc` before debugging a console. Same ISA, new body: no `con_core` row; run the port dictionary on the new core, with `FSOC_EMU_UART_GAP` if `accept` emits more than one byte per key. New kernel id: a `con_core` row, and do not clear the stack in `quit`. A CG=I blink hook must not touch `cpu.kit` when the kit is 0. One Verilator per `obj_dir`.

## Anti-patterns

- Blink/HEX-only “kernel”.
- App sources under `fsys/fasm/`.
- Reusing `fsys/host/cross.4th` (J1) for an MCU STC/ITC colon.
- Copying `fsys/common` when the cross cannot parse it — bind the same names in the new cross instead.
