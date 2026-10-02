# Proposal

## Why

Сейчас `fsys/kernel/avr` — цикл `PB0`, а не Форт-система. ATmega8 — class 1 (готовый AVR, не soft-CPU). Нужны те же слои, что у j1a/j1b: fasm, kernel-консоль, хост-кросс, common/extra, приложение снаружи.

## What Changes

- Профиль `avr`: EX-C=S (STC), FMAP `D-S-A-M-3-F`.
- `kernel.4th` — примитивы, словарь, `:`, `quit`, UART. Не мигание.
- Хост `avr-cross` дописывает `fsys/common` и `fsys/avr/extra.4th` в Intel HEX.
- `s" blink" s" 1" option:` дописывает `firmware/blink.fs`, как лампа дописывает `firmware/lamp.fs`.
- Сборка AVR требует `s" fsys" sys:`. Пустой `sys:` (swapforth) hex не пишет.

## Capabilities

### New Capabilities

### Modified Capabilities

- `fsys`: ядро AVR — консоль; extra и release в `fsys/avr/`.
- `forth-cross`: EX-C=S; `blink` — приложение, не текст `[asm]`.

## Impact

- `fsys/kernel/avr/`, `fsys/host/avr-cross.4th`, `fsys/avr/`, `fsoc/tasks/cg-f.4th`, `firmware/blink.fs`, проекты `soc_atmega8*`, тесты, `AGENTS.md`.
- `fsoc/tasks/soc.4th` имя `avr` не содержит.
