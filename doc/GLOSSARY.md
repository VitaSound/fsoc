# Glossary (fsoc)

Краткий словарь для человека (имена как в коде). Вход: [README.md](../README.md), [CONTRIBUTING.md](../CONTRIBUTING.md). Оси CPU: [FMAP-INDEX.md](FMAP-INDEX.md).

Short terms for humans. English names match the Forth words and paths.

## День 1 / Day 1

| Term | Meaning |
|------|---------|
| **task** | What to build (`blinky`, `soc`, `dual-mcpu`, …). Set with `s" …" task:` in `target.4th`. |
| **target** | How to run it (`emulation`, `quartus`, `yosys`, `proteus`). |
| **sys** | Image tool. On task `soc` must be `s" fsys" sys:`. Empty → `needs fsys`. |
| **fsys** | Console image layers: fasm → kernel → host-cross → extra → firmware. |
| **FSOC_HOME** | Repo root for all repository paths. Project dir is cwd. |

## Дальше / More

| Term | Meaning |
|------|---------|
| **board** | Pin/clock description under `boards/`. Omit for pure emulation. |
| **design** | fhdlgen top under `designs/` (path from `FSOC_HOME`). |
| **cpu** | Forth/MCU profile id in `fsoc/cpu.4th` (`j1a`, `avr`, …). Empty on `soc` → `j1a`. |
| **model** | Chip part file under `fsys/fasm/<cpu>/` (e.g. `atmega8`). |
| **fasm** | Host assembler (comma words). Writes HEX/hex words for the target. |
| **kernel** | Forth console in `fsys/kernel/<id>/` (`KEY`/`EMIT`, `:`, `quit`, `words`). |
| **cross** | Host compiler that loads Forth into the kernel image. |
| **extra / release** | Chip helpers; release keeps only the app closure. |
| **CG** | Codegen class on the profile (I = J1 kit, F = fasm HEX, E = external). |
| **MM / EX-C** | FMAP memory model and colon execution style — [FMAP-INDEX.md](FMAP-INDEX.md); full canon in [frules](https://github.com/VitaSound/frules) (RU `docs/FORTH-*.md`). |
| **MPSoC / dual-mcpu** | Two micro-cores with different images — [mcpu-pingpong.md](mcpu-pingpong.md). |
| **iomap / CSR** | One Forth map → `csr.fs`, `iomap.vh`, `csr.json`. |

Historical note: an earlier second image tool (SwapForth under `swapforth/`) was removed; do not restore it.
