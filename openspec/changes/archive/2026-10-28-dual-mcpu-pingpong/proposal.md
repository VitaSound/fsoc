# Proposal: dual-mcpu-pingpong

## Why

В пресс-релизе «два ядра J1» читаются как профили j1a/j1b, а не как два CPU на одной шине. Идея MPSoC в репозитории не была закреплена живым примером. Нужен тонкий демо: два микроядра с **разным** кодом и обменом сообщениями.

## What Changes

- Задача `dual-mcpu`: два экземпляра MCPU, private RAM, shared mailbox по адресу 62.
- Два образа fasm: `firmware/mcpu_ping.4th` и `firmware/mcpu_pong.4th` → `cpu0.hex` / `cpu1.hex`.
- Эмуляция Verilator печатает `pin ping 1` / `pin pong 1`.
- Проект `projects/baremetal/dual_mcpu_emul`, тест `tests/dual_mcpu_pingpong_test.4th`.
- Документация RU: `doc/mcpu-pingpong.md`, ссылки из README / CONTRIBUTING / roadmap.

## Capabilities

### New Capabilities

- `mpsoc`: контракт двух ядер / разных образов / ping-pong в эмуляции.

### Modified Capabilities

- (нет)

## Impact

- `cpu/mcpu/dual_pingpong.v`, `fsoc/tasks/dual-mcpu.4th`, `fsoc/tasks/dual_mcpu_main.cpp`, `fsoc/load.4th`.
- Не трогает `sys: fsys` и сетку `con_core`.
