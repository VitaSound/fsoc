# Proposal: 8051 soft + hard

## Why

Нужен MCS-51 в fsoc: Proteus (hard AT89C52) и soft R8051 на Verilator/Colorlight, с общим fsys и выбором тела.

## What Changes

- Профиль `cpu: 8051` (class 1, MM=D, EX-C=S, CG=F), `cpu-ref` `at89c52`
- Option `body` soft|hard; `code` / `iram` / `xram` размеры
- Soft: vendored R8051, byte hex, Verilator + Yosys Colorlight fit
- Hard: Intel HEX, `target: proteus`, опционально `tools/8051-con` (s51)
- Полные слои fsys + con_core (soft)

## Capabilities

### Modified Capabilities

- `forth-cross`: профиль 8051, soft/hard, Intel HEX vs byte hex
- `fsys`: kernel console 8051, con_core ряд

## Impact

- `fsoc/cpu.4th`, `fsoc/tasks/cg-8051.4th`, `cpu/8051/`, `fsys/**/8051/`, проекты, тесты, `doc/`
