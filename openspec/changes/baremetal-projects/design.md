# Design

## Context

Задача `blinky` — Verilog. Задача `soc` — Forth-система. Голый AVR не должен идти через `soc` с пустым `sys:` (это swapforth и стоп).

## Goals / Non-Goals

**Goals:** `projects/baremetal/` для всего `blinky_*`; `blinky_atmega` через `fasm`; лог AVR как у J1.

**Non-Goals:** переименование `soc_*`; запуск Proteus; HDL-blinky на AVR.

## Decisions

- Часть чипа задаёт `avr-part` после `atmega8` (и других part-файлов). Hardware: `atmega8(avr)`.
- Занятость: `fasm-pc @ 2*` из `avr-flash 2*` байт, строка как у J1 kit RAM.
- Исходник мигалки: `firmware/blink_avr.4th`, не `fsys/fasm/` и не kernel.
