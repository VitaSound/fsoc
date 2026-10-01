# Proposal

## Why

Нужен тот же J1a, но с бит-последовательным трактом: в регистрах только состояние, а АЛУ и управление — таблицы, как ПЗУ на дискретке. На Colorlight ответ блока `DP16KD` приходит на следующем такте.

## What Changes

- Профиль `j1abs` (A Bit Serial): класс 0, FMAP `V-V-A-0-I`, MM=V, EX-C=V, CG=I, BM=C. Образ и ядро Forth берутся у `j1a` через поле `cpu-port`. Ряда `con_core` нет.
- `cpu/j1/j1abs/j1.v`: синхронные `alu_rom` и `ctrl_rom` (`512×32`) и стековое ОЗУ. Порты модуля `j1` те же, что у j1a.
- `fsoc/tasks/soc.4th` не содержит литерала `j1abs`.
- Проекты: `baremetal/blinky_j1abs`, `soc_j1abs`, `soc_j1abs_blink`.

## Capabilities

### Modified Capabilities

- `forth-cross`: профиль `j1abs`, порт образа, таблицы в `DP16KD`, без ряда `con_core`, без литерала в `soc.4th`.

## Impact

- `fsoc/cpu.4th`, `fsoc/tasks/soc.4th`, `fsoc/tasks/cg-i-blink.4th`, `cpu/j1/j1abs/`, `firmware/blink_j1abs.4th`, `rtl/tb_j1abs.v`, `rtl/tb_j1_ref.v`, `tests/j1abs_test.4th`, `README.md`, `AGENTS.md`.
