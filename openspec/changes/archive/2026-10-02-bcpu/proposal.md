# Proposal

## Why

Нужен свой процессор в Verilog, без VHDL и без ядра AVR. Система команд — bit-serial (Richard James Howe): аккумулятор, eForth уже собран в `bit.hex`. Тайминг побитового автомата прошивке не нужен.

## What Changes

- Профиль `bcpu`: класс 0, FMAP `U-M-B-A-3-F`, MM=U, EX-C=B, CG=F, BM=C, клетка 16 бит, `cpu-ref` тоже `bcpu`.
- `cpu/bcpu/bcpu.v` считает команду 16-битным АЛУ. В шапке ссылка на howerj/bit-serial. VHDL не копируется.
- `fsys/fasm/bcpu` — только слова-запятые. Ядра fsys и ряда `con_core` нет.
- CG=F пишет слова по 16 бит. Пустой `sys:` не подставляет SwapForth: нужен `s" bcpu" sys:`.
- Эмуляция: baremetal blink, консоль eForth, soc blink. Синтез Yosys на Colorlight считает ядро, память и UART.

## Capabilities

### New Capabilities

### Modified Capabilities

- `forth-cross`: профиль `bcpu`, слово-образ вместо Intel HEX, останов без `sys: bcpu`, без литерала в `soc.4th` и без `con_core`.

## Impact

- `fsoc/cpu.4th`, `fsoc/tasks/cg-f.4th`, `fsoc/tasks/cg-bcpu.4th`, `cpu/bcpu/`, `fsys/fasm/bcpu/`, `firmware/blink_bcpu.4th`, `firmware/blink_bcpu_soc.4th`, `rtl/tb_bcpu.v`, `tests/bcpu_fasm_test.4th`, `tests/bcpu_test.4th`, `README.md`.
