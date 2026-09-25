# Tasks

## 1. Дамп

- [x] 1.1 `emu/trace.h` / `emu/trace.cc`: `Trace`, окно 4096 тактов или `FSOC_EMU_CYCLES` если больше, `trace.vcd`, отказ без `VM_TRACE`. `targets/emulation.4th`: копировать файлы; `--trace` и `-DVM_TRACE` только в строке `*_main.cpp`, когда `FSOC_EMU_TRACE` непуст. Проверить: `tests/blinky_test.4th` без переменной — в `sim.sh` нет `--trace`.
- [x] 1.2 Крюки `open` / `dump` / `end_cycle` в `fsoc/tasks/blinky_main.cpp` и `fsoc/tasks/soc_main.cpp`. `soc_feed.cpp` не менять. Проверить: `FSOC_EMU_TRACE=1 FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1` пишет непустой `trace.vcd`, в `sim.sh` одно `--trace`, журнал содержит `pin led 0` и `pin led 1`.

## 2. Запрос и документы

- [x] 2.1 `tools/peek.sh`, skill `.cursor/skills/wavepeek` (3.0.1), `.gitignore` (`trace.vcd`). README, AGENTS.md, CHANGELOG: `FSOC_EMU_TRACE`, `trace.vcd`, peek. Проверить: `fmix test` зелёный без `wavepeek` в PATH.
