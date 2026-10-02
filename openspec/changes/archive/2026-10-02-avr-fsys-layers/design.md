# Design

## Context

J1 class 0: ядро собирается вместе с Verilog. ATmega8 class 1: кремний готов, ядро — прошивка STC (`rcall`/`ret`). Словарь колонов во flash пишет хост; интерактивный `:` на цели кладёт ITC в SRAM (исполнять native из SRAM AVR не умеет). SPM / RP=4 — позже.

## Goals / Non-Goals

**Goals:**

- Слои как у j1a: fasm → kernel → host cross → common/extra → firmware.
- Семантика kernel: `words`, `:`, `quit`, ` ok`.
- Мигание — `firmware/blink.fs` и `'BOOT`.

**Non-Goals:**

- SPM, AmForth, запуск Proteus, `jmp`/`call` на ATmega8.

## Decisions

1. Стеки: Y — data (TOS в r16:r17), SP — return. Карта SRAM из полей чипа.
2. CG=F вызывает шаг fsys внутри `cg-f.4th`, не `soc-cg-i`.
3. `common.4th` компилирует хост; если имени нет в ядре, кросс останавливается явной фразой.
4. Extra — порты `io@`/`io!`, не константы в `words.4th`.

## Risks / Trade-offs

- [common тянет слова J1] → ядро даёт тот же набор имён, что кросс перехватывает плюс примитивы eForth; нехватку закрывать словами kernel, не копировать common.
- [rcall ±2K] → весь образ ATmega8 в 4096 словах; дальние цели не нужны.
