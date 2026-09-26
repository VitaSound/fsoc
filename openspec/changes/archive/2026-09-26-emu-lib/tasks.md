# Tasks

## 1. Такт и пин

- [x] 1.1 Добавить `emu/clock.h` / `emu/clock.cc`: `env_int`, `env_str`, `Clock` (такт 50 МГц, `t`, `cycles`, `FSOC_EMU_CYCLES`, `FSOC_EMU_FAST`, realtime-пауза по событию, SIGINT → 130). Проверить: `fsoc/tasks/blinky_main.cpp` переписан на `Clock`, без `sleep_until` / `std::signal`; `tests/blinky_test.4th` с `FSOC_EMU_EDGES=2` зелёный.
- [x] 1.2 `targets/emulation.4th`: `sim.sh` компилирует `*.cc` библиотеки и `*_main.cpp`; блок `trap`/130 не меняется. Проверить: `cd projects/blinky_emul && fsoc --build` с `FSOC_EMU_EDGES=2 FSOC_EMU_FAST=1` код 0.

## 2. UART и сеанс

- [x] 2.1 Добавить `emu/uart.h` / `emu/uart.cc`: `RxShift(bit_clocks)`, `TxDec(bit_clocks)` из `soc_main.cpp`. Делитель — `-DFSOC_UART_BIT=<n>` в `sim.sh` из одного значения таргета; `j1_wrap.v` получает параметры `CLK_HZ` / `BAUD` (пока значение, дающее 104), дизайн передаёт их `hdl-inst-param`. Проверить: `rg "104" fsoc/tasks/*.cpp emu/` пусто; `tests/soc_test.4th` сценарий `1 2 + .` зелёный.
- [x] 2.2 Добавить `emu/script.h` / `emu/script.cc`: `Session` (фазы boot → sync → lines → done, признаки ` ok` и `?`), источники строк `EnvLines`, `HostLines` (stdin / `con_line`). Проверить: `tests/soc_test.4th` сценарии `DOUBLE`, `P`, `NOWORD`, `words` зелёные.
- [x] 2.3 Переписать `fsoc/tasks/soc_main.cpp` на `Clock` + `RxShift` / `TxDec` + `Session` + `con_panel_open`; удалить `saw_on`, `saw_off`, `toggles`, `pin_ready`, `window.find("lamp`; `con_pin("led")` вызывается всегда в виде `pin`. Коды выхода по спеке. Проверить: `wc -l fsoc/tasks/soc_main.cpp` меньше 100; `rg "lamp|toggles" fsoc/tasks/soc_main.cpp` пусто.
- [x] 2.4 `tests/soc_blink_test.4th`: прогоны с `FSOC_EMU_CYCLES=200000` вместо ожидания оракула; проверка `lamp on` / `lamp off` (`term`) и `pin led 0` / `pin led 1` (`pin`) остаётся в тесте. Проверить: `fmix test` зелёный, код выхода 0 в обоих прогонах.

## 3. Шаг прошивки

- [x] 3.1 `cpu/j1/j1_wrap.v`: вход `dump`; `always @(posedge clk) if (dump) $writememh("firmware.hex", ram);`. `designs/lib/j1_wrap.4th` и `designs/soc_*.4th`: порт `dump` у обёртки и у `top` (в эмуляции — вход, на плате — 0). Проверить: `top.v` содержит `dump`, Icarus компилирует `j1_wrap.v`.
- [x] 3.2 Добавить `fsoc/tasks/soc_feed.cpp`: читает плоский файл из `FSOC_EMU_FEED`, ведёт `Session`, по `done()` поднимает `dump` на такт, выходит 0; `sim.sh` собирает `obj_dir/Vtop_feed` из `*_feed.cpp`. Проверить: запуск `Vtop_feed` на `nuc.hex` + плоском `swapforth.fs` даёт `firmware.hex` на 4096 строк, отличный от `nuc.hex`.
- [x] 3.3 `fsoc/tasks/soc.4th`: слово `soc-flatten ( src dst -- )` раскрывает `include <имя>` (каталог файла, затем `swapforth/common/`) в один файл `feed.fs`; `soc-feed` вызывает `Vtop_feed`, а не `sim.sh` с `FSOC_EMU_SNAPSHOT`. Удалить `load_forth`, `resolve_include`, `snapshot_ram` из C++. Проверить: `rg "FSOC_EMU_SNAPSHOT|snapshot_ram|top__DOT__" fsoc/ emu/ targets/` пусто; `feed.fs` не содержит строк `include`; `tests/soc_test.4th` — `firmware.hex` 4096 строк и `cmp` с `nuc.hex` различен.

## 4. Документация и проверка

- [x] 4.1 README, AGENTS.md: `emu/` — библиотека (con, clock, uart, script); переменные `FSOC_EMU_CYCLES` добавлена, `FSOC_EMU_SNAPSHOT` удалена; `soc_blink` быстрый прогон — через `FSOC_EMU_CYCLES`. CHANGELOG `[Unreleased]` — Changed/Removed. Проверить: `rg FSOC_EMU_SNAPSHOT README.md AGENTS.md` пусто.
- [x] 4.2 `fmix check --stage all` зелёный; `wc -l fsoc/tasks/*_main.cpp` — blinky < 40, soc < 100.
