# Proposal

## Why

Консоль SwapForth на Colorlight нельзя прогнать в Verilator: любая плата в задаче SoC после feed переписывает топ без UART и стирает `sim.sh`, а `sim.sh` всегда ставит 50 МГц. Делитель от 50 МГц при такте платы 25 МГц ломает сеанс.

## What Changes

- Проект `projects/soc_emul_colorlight_5a_75e_v6_0`: задача `soc`, таргет `emulation`, плата `colorlight_5a_75e_v6_0`, дизайн `designs/soc_console.4th`.
- Эмуляция с загруженной платой берёт `CLK_HZ` у тактового ресурса платы. Без платы остаётся 50 МГц.
- Топ эмуляции сохраняет порты `uart_rx`, `uart_tx`, `rst`, `dump`. Параметры `BOARD`, `NO_UART`, `LED_LOW`, `TIMER_DIV` в него не передаются. `sim.sh` не удаляется.
- Yosys-лампа на той же плате не меняется: feed на 50 МГц, затем топ без UART и без `sim.sh`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `soc`: консоль на эмуляции Colorlight отвечает `3 ok` при такте 25 МГц и тех же портах UART, что у `soc_emul`.
- `emulation`: `sim.sh` пишет частоту загруженной платы, иначе `50000000`.
- `builder`: эмуляция SoC с платой оставляет `sim.sh` и не пишет `.qsf`. Карту пинов по-прежнему не выпускает.

## Impact

- `fsoc/registry.4th`, `targets/emulation.4th`, `fsoc/tasks/soc.4th`
- `projects/soc_emul_colorlight_5a_75e_v6_0/target.4th`
- `tests/soc_test.4th`
- README, AGENTS.md, CHANGELOG, версия 0.6.0
