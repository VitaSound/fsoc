## 1. Выдача Quartus

- [x] 1.1 Собрать длинную строку Verilog до записи в `top.v`. Проверка: в `top.v` проекта `soc_terasic_de0nano` есть `.led(led)` на одной строке.
- [x] 1.2 Писать `VERILOG_INCLUDE_FILE` для `` `include "…vh" `` и `HEX_FILE` для файла `$readmemh` в каталоге проекта. Проверка: `soc_board_test` ищет обе строки в `soc.qsf`.

## 2. Регистр светодиода

- [x] 2.1 Консоль передаёт `USE_REGIO=1` и включает `regio.v`. Проверка: `soc_test` и `soc_board_test` видят `USE_REGIO(1)` и `regio.v`.

## 3. Запись

- [x] 3.1 README: объёмы fit 2026-09-27 02:10:30. `doc/quartus-ii-11.md`: ошибки и как они закрылись. CHANGELOG и версия `0.8.0`. Дорожная карта: проверка на плате Altera, затем сборка под Xilinx.
