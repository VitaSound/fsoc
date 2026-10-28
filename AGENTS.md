# AGENTS.md — fsoc

Forth-native SoC builder (LiteX analogue) for VitaSound. Host language is **Gforth**. HDL generation for modules lives in [fhdlgen](https://github.com/VitaSound/fhdlgen) >= 0.5 (`fhdlgen build <design> --out <dir>`); this repo is boards, toolchains, iomap, firmware, and tools. Designs do not read the environment.

Human (RU) entry: [README.md](README.md), [CONTRIBUTING.md](CONTRIBUTING.md), [doc/MAP.md](doc/MAP.md), [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).

## Layout

| Path | Role |
|------|------|
| `fsoc/` | IR, DSL, emit, `cpu.4th`, `sys.4th`, tasks |
| `boards/` | Clock, pins, family |
| `designs/` | fhdlgen tops (no board/project path) |
| `emu/` | Verilator console library (no task names) |
| `rtl/` | Pure Verilog leaves |
| `cpu/<family>/` | Soft-CPU kits (`j1`, `bcpu`, `mcpu`, `z80`, `8051`, …) |
| `fsys/fasm/<id>/` | Host assembler only |
| `fsys/kernel/<id>/` | Forth console kernel |
| `fsys/host/` | Host cross |
| `fsys/<id>/` | extra / release |
| `firmware/` | Apps and fasm blinks |
| `projects/{baremetal,soc,standalone}/` | Working dirs; git keeps only `target.4th` |
| `targets/` | emulation / quartus / yosys emitters |
| `tests/` | fmix / gforth suites |
| `doc/` | Human notes (MAP, GLOSSARY, FMAP-INDEX, CPU notes) |
| `openspec/specs/` | Requirements |

Profile and image-tool detail: `fsoc/cpu.4th`, `fsoc/sys.4th`, per-CPU `doc/<id>.md`. Human how-to: `doc/add-cpu.md`. Agent rule: `.cursor/rules/fsoc-cpu-target.mdc`. Solved core pitfalls: `j1abs-core.mdc`, `bcpu-console.mdc`.

**MPSoC demo:** task `dual-mcpu`, `projects/baremetal/dual_mcpu_emul`, [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md). Not an fsys console; two MCPU images + mailbox.

Blinky (no Forth) under `projects/baremetal/`. Empty `sys:` on task `soc` stops (`needs fsys`). AVR projects set `s" atmega8" model:` (or another part). Paths only from `FSOC_HOME`. Tests use temp dirs (`tests/fixture.4th`), never write into `projects/*`.

## Commands

```bash
fmix packages.get
fmix test
# selective long cores: tools/pre-commit.sh / pre-push.sh + tools/long-core-select.sh
fsoc version
cd projects/baremetal/blinky_emul && fsoc --build
cd projects/baremetal/blinky_atmega && fsoc --build
cd projects/baremetal/dual_mcpu_emul && FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 fsoc --build
cd projects/soc/soc_emul && fsoc --build
```

## Process

Non-trivial changes: OpenSpec in `openspec/`. Before commit: short tests + flint (+ selective long). Full gate: `fmix test`, `flint`, `fcov`.

If a build value has no source file, stop and ask — do not hardcode a stand-in list.

## ISA / fasm coverage rules

**D1 — полнота по уровню ISA.** Слой `fsys/fasm/<id>/words.4th` обязан покрывать все инструкции архитектуры. Инструкция, намеренно исключённая, помечается как `intentional-absent` с обоснованием (например, «только XMEGA», «нет на AT89C52»). «Экономия ROM» или «и так работает» не принимаются как причина обрезки spec.

**D2 — подмножества через feature-gates, не урезанием words.4th.** Синтезируемые ядра-подмножества (AT1200-lite, j1abs без mul/div) описываются chip-profile + `isa-feat.4th`-гейтами (`feat-define`, `have`, `need`). Файл `words.4th` *никогда* не обрезается под конкретный чип — гейты накладываются сверху на полный spec.

**Golden-датасеты — offline bootstrap.** Канон: `s" <arch>" gen-golden` (`fsoc/futils/gen_golden.4th`) из `tests/golden-src/<arch>/programs.4th`. В CI — статический `tests/golden/` (закоммичен). Внешние ассемблеры (`gen-golden-external` / `tools/gen_golden.py --external`) — опциональный offline parity, не CI.

## New CPU / MCU

Human how-to: [`doc/add-cpu.md`](doc/add-cpu.md) ([eng](doc/add-cpu-eng.md)). Agent rule (same canvas + pitfalls): `.cursor/rules/fsoc-cpu-target.mdc`. Skill: `add-cpu-target`. Specs: `openspec/specs/forth-cross/spec.md`, `openspec/specs/fsys/spec.md`.

New ISA → new `cpu:` id with fsys layers: `fsys/fasm/<id>/` → `fsys/kernel/<id>/` (console, not blink) → `fsys/host/<id>-cross.4th` → `fsys/<id>/extra.4th` → `firmware/*.fs`. New chip of an existing ISA → fasm part file only. Empty `sys:` on `soc` stops. Branch by CG in the emitter, not by a cpu id literal in `soc.4th`.

New **fsys console** id MUST join `tests/con_core_test.4th` (session, JSON, `con_words.py`, BS/DEL).

Before review of a new `cpu:` or a new body of the same ISA: three emulation sessions (spec forth-cross). Baremetal blink and soc blink with `FSOC_EMU_CON=pin` `FSOC_EMU_EDGES=4` each show `pin led 0` and `pin led 1` at least twice. Soc `s" fsys" sys:` answers `words` and at least two expressions (`1 2 + .` → `3  ok`, plus `:` or `.s`). Do not export `FSOC_EMU_UART_GAP` for that hand check. A new kernel runs its `con_core` row. A port runs the word script outside `fmix` when required.
