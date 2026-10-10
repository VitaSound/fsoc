# Adding a CPU / MCU in fsoc

How to add a target platform: a new `cpu:` id and fsys layers. Not a blink HEX “instead of a kernel”.

Russian: [add-cpu.md](add-cpu.md). FMAP axes: [FMAP-INDEX.md](FMAP-INDEX.md). Requirements: [`openspec/specs/forth-cross/spec.md`](../openspec/specs/forth-cross/spec.md), [`openspec/specs/fsys/spec.md`](../openspec/specs/fsys/spec.md).

## Id vs chip

| Case | What to do |
|------|------------|
| New **ISA** | New id in [`fsoc/cpu.4th`](../fsoc/cpu.4th) (`cpu-new`: FMAP class, MM, EX-C, CG, BM) and the full layer set below |
| New **package** of the same ISA (`atmega328p` next to `atmega8`) | Part file only under `fsys/fasm/<id>/`. Manifest `model:` is that file id; empty `model:` uses `cpu-ref` |

Examples: `avr` (class 1, MM=D, EX-C=S, CG=F), `j1a` (class 0, MM=V, EX-C=V, CG=I), `bcpu` (class 0, MM=U, EX-C=B, CG=F).

## Layers (same canvas as j1a / j1b / avr)

| Layer | Path | Role |
|-------|------|------|
| Assembler | `fsys/fasm/<id>/` | Comma words only. No dictionary, no `quit`, no app loop |
| Kernel | `fsys/kernel/<id>/kernel.4th` | Forth **console** in that fasm: stacks, `@` `!`, UART `KEY`/`EMIT`, `:` `;`, `quit`, `words`, ` ok`. Not blink/lamp |
| Host cross | `fsys/host/<id>-cross.4th` | Host compiles Forth into the image. Do not reuse J1 ALU ops for an MCU colon |
| Extra / release | `fsys/<id>/extra.4th`, `release.4th` | Chip words on the kernel. Not the assembler |
| App | `firmware/<name>.fs` | `'BOOT` / I/O. Manifest option (`lamp`, `blink`) |

`fsys/common` is **one** text for ids whose cross can load it. If it cannot, the cross supplies the same **names** (`if` `then` `variable` …); do not copy `common.4th` per CPU.

## Build wiring

- Manifest `cpu:` picks the profile; **CG** picks the emitter. `target:` is how it runs (emulation, quartus, proteus).
- Put **no** new cpu id literal in `fsoc/tasks/soc.4th`. Branch inside the CG file already registered (`cg-f.4th` for CG=F, `soc-cg-i` for CG=I).
- Empty `sys:` on task `soc` **stops** (`needs fsys`). Every console image **must** set `s" fsys" sys:`. Baremetal blink is task `blinky` plus `cpu:`; it does not read `sys:`. fasm in the log is the assembler, not a task name.
- **CG=I** (class 0 J1): Verilog kit under `cpu/j1/<id>/`, image via `soc-fsys`.
- **CG=F** (class 1/2 MCU, HEX): host fasm + fsys layers, no `Vtop_feed`. Log matches J1: `Hardware` prints `atmega8(avr)`, `Software` prints `firmware.hex: <used> bytes of <flash>`.
- **CG=E** (stm8 today): no hex; external kernel (e.g. stm8ef). Do not invent a fasm kernel unless the profile changes.

## Do not

- Treat the kernel as “the whole program” (no `sbi DDRB` as `kernel.4th`).
- Put application source in `fsys/fasm/<id>/`.
- Mix Gforth hosted idioms into the target kernel without an FMAP/EX-C decision.
- Import AmForth/FlashForth as the fsoc kernel unless the manifest names that tool as `sys:`.
- Hardcode a stand-in word list when the image source is missing — stop and ask.
- Ship a new fsys console id without wiring `tests/con_core_test.4th`.

## Console grid (required for a new fsys id)

A new ISA with a Forth **console** kernel MUST join the shared REPL grid. A chip part of an existing id does **not**.

1. Same `accept` erase as j1a/j1b/avr: bytes 8 and 127, decrement only when the line is non-empty, TX `BS SPACE BS`.
2. Manifest helper in [`tests/con_session.4th`](../tests/con_session.4th); a row in [`tests/con_core_test.4th`](../tests/con_core_test.4th).
3. Dictionary JSON via [`doc/j1-word-graph/build.py`](j1-word-graph/build.py) (`fsys-<id>*.json`).
4. Every JSON name tagged in [`tests/con_words.py`](../tests/con_words.py) (`run` / `colon` / `skip` with a reason).
5. Id-only words in a separate `*_test.4th` (see [`tests/avr_con_test.4th`](../tests/avr_con_test.4th)). Do not copy the shared echo/BS/`+`/`.s`/`: `/`words` lines.

```bash
export FSOC_HOME="$PWD"
cd tests && gforth con_core_test.4th
# or from the repo root:
fmix test
```

Without simavr the AVR slice skips. Same ISA, different body (e.g. `j1abs`, port of `j1a`): do not add a `con_core` row; run the port word script on the new core.

## Before review: three emulation sessions

A green short `*_test.4th` is not the handoff. Spec `forth-cross` requires three logs:

1. Baremetal `blinky` + `cpu:`, `FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1`. `pin led 0` and `pin led 1` each appear at least twice. One pulse then a stop is a failure.
2. Soc with that id's lamp or blink option, same pin settings. Both levels repeat. If the image prints text, both the on and off lines are in the log. ` ok` is not required.
3. Soc `s" fsys" sys:` answers `words` with names from that image's dictionary, and at least two expressions (`1 2 + .` → `3  ok`, plus a colon word or `.s`). A new kernel id: run its `con_core` row, do not only add the file. Same ISA, other body: run the port word script (e.g. `gforth tests/j1abs_words.4th`). Keep a multi-minute script out of `*_test.4th` so `fmix` does not sit silent; still run it at this step.

For that hand console check, do not export `FSOC_EMU_UART_GAP`.

## Related

- Tree map: [MAP-eng.md](MAP-eng.md)
- Contributing: [CONTRIBUTING.md](../CONTRIBUTING.md)
- Agent contract (same canvas + debug pitfalls): [`.cursor/rules/fsoc-cpu-target.mdc`](../.cursor/rules/fsoc-cpu-target.mdc), skill `add-cpu-target`
