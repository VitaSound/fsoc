# Proposal

## Why

Полная сборка Quartus II 11.1 на Terasic DE0-Nano дошла до успешного fit, но первая выдача ломала синтаксис топа, не показывала `iomap.vh` и `firmware.hex` в списке файлов и держала `led` на земле. Консоль SwapForth должна оставлять регистр светодиода в нетлисте.

## What Changes

- Таргет Quartus собирает строку Verilog целиком, если `read-line` вернул полный буфер. Токен вроде `.led(led)` больше не рвётся посередине.
- `` `include "…vh" `` внутри листа становится `VERILOG_INCLUDE_FILE`. Файл не попадает в `VERILOG_FILE`.
- Файл из `$readmemh("…")`, лежащий в каталоге проекта, становится `HEX_FILE`, чтобы Quartus II 11 показал его в Project Navigator. Образ RAM по-прежнему читает `$readmemh`.
- `designs/soc_console.4th` включает `regio.v` и передаёт `USE_REGIO=1`. Запись `1` по `IO-LED` (`$400 io!`) выходит на пин `led`.
- Рабочий проект Quartus — `projects/soc_terasic_de0nano`. Проекты и платы VitaSound EP4CE10 и RZ-EasyFPGA удалены.
- Выводы по ошибкам сборки записаны в `doc/quartus-ii-11.md`. Объёмы fit — в README.

## Capabilities

### New Capabilities

### Modified Capabilities

- `soc`: консоль на плате инстанцирует регистр `led`, а `.qsf` называет `iomap.vh` и `firmware.hex`. Строка инстанса в `top.v` содержит `.led(led)` целиком.

## Impact

- `targets/quartus.4th`, `designs/soc_console.4th`
- `tests/soc_board_test.4th`, `tests/soc_test.4th`
- Удалены `boards/vitasound_ep4ce10.4th`, `boards/rz_easyfpga.4th` и три каталога `projects/`
- README, CHANGELOG `[0.8.0]`, `doc/roadmap.md`, `doc/quartus-ii-11.md`
