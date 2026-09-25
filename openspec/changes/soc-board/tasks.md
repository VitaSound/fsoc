# Tasks

## 1. Частота и делитель

- [ ] 1.1 `fsoc/platform.4th`: поле `io.clock-hz`, слова `plat-clock-hz` (внутри `io-begin`), `io.clock-hz@`; три платы задают `50000000 plat-clock-hz` у `clk50`. Проверить: `tests/platform_test.4th` — `io.clock-hz@` трёх плат равно 50000000, у `user_led` — 0.
- [ ] 1.2 `cpu/j1/j1_wrap.v` и `cpu/j1/uart.v`: параметры `CLK_HZ`, `BAUD`; делитель `CLK_HZ / BAUD` внутри. `designs/lib/j1_wrap.4th` объявляет параметры; `designs/soc_*.4th` передают их `hdl-inst-param` из параметров fhdlgen (`--param CLK_HZ=… --param BAUD=…`). Проверить: Icarus компилирует обёртку с `CLK_HZ=50000000`; `top.v` содержит `CLK_HZ(50000000)`.
- [ ] 1.3 `targets/emulation.4th`: такт эмуляции 50000000 объявляется как частота таргета; `sim.sh` получает `-DFSOC_UART_BIT=$((CLK_HZ / BAUD))` из тех же чисел, что ушли в `--param`. Тесты `soc_test`, `soc_blink_test`: `FSOC_EMU_CYCLES` ×4. Проверить: `rg "\b104\b|\b434\b" fsoc/ emu/ tests/ targets/` пусто; `fmix test` зелёный.

## 2. Плата

- [ ] 2.1 `targets/quartus.4th`: `quartus-map-sub ( res index sub port -- )` по `sub.pins$`; `abort" quartus-map-sub: missing subsignal"`. Проверить: `tests/platform_test.4th` пишет `.qsf` во временный каталог с `PIN_114 -to uart_tx`, `PIN_115 -to uart_rx`.
- [ ] 2.2 `fsoc/tasks/soc.4th`: при непустом `project.board@` — `board-load`, `request clk50 / user_led / serial`, `quartus-project s" soc"`, `quartus-top`/`quartus-vfile` из `top-module`, `quartus-clock` из `io.clock-hz@` (период в нс), `quartus-map` `clk` / `led`, `quartus-map-sub` `uart_tx` / `uart_rx`. Без платы — ничего. Проверить: `rg "quartus|emulation" fsoc/tasks/soc.4th` находит только слова `quartus-*` API, не имена таргетов как ветки; `tests/soc_test.4th` зелёный.
- [ ] 2.3 Дизайн: параметр `BOARD` — при `BOARD=1` порты `rst` и `dump` не выходят из `top`, а привязаны к 0 через `comb`/`assign` fhdlgen. Задача передаёт `--param BOARD=1` при заданной плате. Проверить: `top.v` платы не содержит `input wire rst`; `top.v` эмуляции содержит.
- [ ] 2.4 Добавить `projects/soc_vitasound_ep4ce10/target.4th` (`soc`, `quartus`, `vitasound_ep4ce10`, `../../designs/soc_console.4th`); `.gitignore` уже пропускает `target.4th`. Добавить `tests/soc_board_test.4th`: сборка во временном каталоге, проверка `soc.qsf` по спеке, `firmware.hex` 4096 строк, отсутствие `sim.sh`, Quartus не вызывался (`build.sh` не запущен). Проверить: `fmix test` зелёный; `git check-ignore -q projects/soc_vitasound_ep4ce10/target.4th` возвращает 1.

## 3. fterm

- [ ] 3.1 `tools/fterm.4th`: backend устройства — `fterm-open ( path -- )` (`r/w open-file`, `stty -F <path> 115200 raw -echo` через `system`), `fterm-write` → `write-file`, `fterm-read` → чтение до ` ok` или `?` с пределом попыток; `fterm-mock` — прежний ответ из памяти; `gforth tools/fterm.4th <path>` открывает устройство, без аргумента — mock. Проверить: `tests/fterm_test.4th` на mock зелёный; ручной прогон на плате даёт `3  ok` (зафиксировать в CHANGELOG).

## 4. Документация и проверка

- [ ] 4.1 README: раздел «SoC на плате» — `cd projects/soc_vitasound_ep4ce10 && fsoc --build --load`, затем `gforth tools/fterm.4th /dev/ttyUSB0`; таблица плат — колонка `serial`. `doc/roadmap.md`: пункт USB-UART на EP4CE10 — Done. AGENTS.md: проект в списке. CHANGELOG `[Unreleased]` — Added; BREAKING про делитель эмуляции. Проверить: `rg soc_vitasound_ep4ce10 README.md AGENTS.md` непусто.
- [ ] 4.2 `fmix check --stage all` зелёный; на машине с Quartus — `sh build.sh` и `sh load.sh` в `projects/soc_vitasound_ep4ce10`, результат в CHANGELOG.
