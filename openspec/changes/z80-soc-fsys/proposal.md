# Proposal

## Why

У профиля `z80` уже есть fasm, standalone и baremetal blink. Задача `soc` всё ещё идёт в `cg-halt`. Нужен полный слой fsys, как у msl16: консоль, host cross, `top_soc` и опция blink.

## What Changes

- Пустой `sys:` по-прежнему останавливается (`needs fsys`). `s" fsys" sys:` пишет **byte hex** (две цифры на строку), не Intel HEX.
- Ядро-консоль `fsys/kernel/z80`, host `z80-cross`, `fsys/z80/extra-min.4th`, `firmware/z80_blink.fs`.
- `cpu/z80/top_soc.v`: TV80, 16 КБ, UART с очередью 128, LED/IO на `$3FF0..$3FF3`.
- Проекты `soc_z80` и `soc_z80_blink`. Ряд `con_core`. Ветвление внутри CG=F (`cg-z80.4th`), не в `soc.4th`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `forth-cross`: z80 + fsys пишет byte hex; без fsys останавливается; ряд con_core.
- `fsys`: консольный kernel z80 в общей сетке сеансов.

## Impact

- `fsoc/tasks/cg-z80.4th`, `cg-f.4th`, `cpu/z80/top_soc.v`, `fsys/kernel/z80/`, `fsys/host/z80-cross.4th`, `tests/con_core_test.4th`, `doc/z80.md`.
