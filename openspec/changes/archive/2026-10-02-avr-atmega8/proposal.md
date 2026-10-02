# Proposal

## Why

Профили `stm8` и `z80` останавливают сборку до hex. Для схемы в Proteus нужен один корпус с портом и UART, чей код хост собирает сам, без `avra`.

## What Changes

- Профиль `avr`: класс 1, MM=D, EX-C=N, CG=F, BM=C, корпус ATmega8.
- Излучатель CG=F пишет Intel HEX для `avr`. `z80` по-прежнему останавливается до hex. CG=E не меняется.
- Таргет `proteus` не запускает симулятор. Мигание `PB0` и текст в USART выбираются опцией `blink`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `forth-cross`: профиль `avr` собирает Intel HEX; `z80` остаётся без образа.

## Impact

- `fsoc/cpu.4th`, `fsys/fasm/avr/`, `fsys/kernel/avr/`, `fsoc/tasks/cg-f.4th`, `targets/proteus.4th`, `tests/avr_fasm_test.4th`, `tests/cpu_test.4th`.
- Задача `soc` не ветвится по имени `avr`. Каталоги `projects/soc_atmega8` и `projects/soc_atmega8_blink` держат только `target.4th`.
