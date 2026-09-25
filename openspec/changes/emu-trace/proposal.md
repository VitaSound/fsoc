# Proposal

## Why

Консоль эмуляции печатает только смену уровня и байт UART. Чтобы спросить «что на проводе в момент t», нужен короткий VCD и CLI, как WavePeek в hdl-modules. Постоянный дамп реалтайм-прогона на 50 МГц слишком велик, поэтому запись включается отдельно и ограничена окном.

## What Changes

- При непустом `FSOC_EMU_TRACE` сборка смотрового бинаря получает `--trace` и `-DVM_TRACE`. `Vtop_feed` этот флаг не получает.
- Библиотека `emu/trace` пишет `trace.vcd` в каталог проекта. Окно по умолчанию — 4096 тактов; `FSOC_EMU_CYCLES` удлиняет окно, если предел больше. После окна файл закрывается, прогон идёт до своего стопа.
- Бинарь без `--trace` при заданном `FSOC_EMU_TRACE` завершается с ошибкой.
- `tools/peek.sh` передаёт `./trace.vcd` в `wavepeek`. Бинарь WavePeek и skill — инструмент хоста, не зависимость `fmix`.
- Без `FSOC_EMU_TRACE` `sim.sh` и прогон не меняются: `--trace` нет, `trace.vcd` не пишется.

## Capabilities

### New Capabilities

### Modified Capabilities

- `blinky`: эмуляция по запросу пишет короткий `trace.vcd` и по-прежнему печатает смену `led`.

## Impact

- `targets/emulation.4th`, `emu/trace.h`, `emu/trace.cc`, `fsoc/tasks/blinky_main.cpp`, `fsoc/tasks/soc_main.cpp`, `tests/blinky_test.4th`, `tools/peek.sh`, `.cursor/skills/wavepeek`, `AGENTS.md`, `README.md`, `CHANGELOG.md`, `.gitignore`.
- `soc_feed.cpp` не меняется. `wavepeek` не ставится в CI.
