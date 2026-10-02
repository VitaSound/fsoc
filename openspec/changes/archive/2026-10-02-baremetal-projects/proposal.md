# Proposal

## Why

Проекты без Forth-системы лежат рядом с SoC. Голый AVR-HEX не проходит те же стадии лога, что J1 (Hardware / Software / `firmware.hex: N bytes of cap`). Нужен каталог `projects/baremetal/`. Мигание — задача `blinky`; fasm — ассемблер, не имя задачи.

## What Changes

- Каталоги `blinky_*` переезжают в `projects/baremetal/`. `soc_*` остаются на месте.
- `blinky` с `cpu: avr` собирает `firmware/blink_avr.4th` в Intel HEX без kernel и без `sys:`.
- Любой CG=F образ AVR печатает `Hardware` (`atmega8(avr)`), затем `Software` и `firmware.hex: <used> bytes of <flash>`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `builder`: пути `projects/baremetal/`, gitignore на два уровня.
- `blinky`: рабочие копии в `projects/baremetal/`; AVR — та же задача.
- `fsys`: голый fasm-образ вне kernel; лог размера flash.
- `forth-cross`: стадии Hardware/Software для AVR.

## Impact

- `.gitignore`, `tests/fixture` callers, `fsoc/tasks/blinky.4th`, `fsoc/tasks/cg-f.4th`, `firmware/blink_avr.4th`, `AGENTS.md`, `README.md`.
- `fsoc/tasks/soc.4th` по-прежнему без литерала `avr`.
