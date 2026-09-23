# Tasks

## 1. Ядро и ассемблер

- [x] 1.1 Положить в `cpu/j1/` переносимые ядро J1 и UART из swapforth и переписать `j1_wrap.v`: RAM грузит `firmware.hex`, запись UART — порт `h# 1000`, чтение готовности — порт `h# 2000`. Проверить, что в `j1_wrap.v` нет инстанса `j1_prompt`.
- [x] 1.2 Добавить Forth-ассемблер J1 и исходник прошивки, которая ждёт свободный UART и посылает `o`, затем `k`. Сборка идёт через `hex2readmem` в `firmware.hex`. Проверить, что запуск ассемблера даёт непустой `firmware.hex` из нескольких слов, а исходник прошивки — Forth, не готовый hex.

## 2. Топ, main и слово задачи

- [x] 2.1 Добавить `designs/soc_top.4th`: порты `clk`, `rst`, `uart_tx`, `` `include `` обёртки и листов ядра, инстанс `j1_wrap`, выход только из `FSOC_SOC_TOP`. Проверить, что в файле нет `projects/`, нет `soc_emul` и нет `j1_prompt`.
- [x] 2.2 Добавить `fsoc/soc_main.cpp`: такт 50 МГц (полупериод 10 нс), сброс на один такт, декодер 8N1 с периодом бита по стартовому биту, байт в `con_uart("tx", ...)`, обрыв по `FSOC_EMU_UART_BYTES`, без паузы при `FSOC_EMU_FAST=1`. Проверить, что файл лежит в `fsoc/`, а в `emu/` нет файла с именем soc.
- [x] 2.3 Добавить `fsoc/soc.4th` со словом `soc-emit-emulation` и подключить его из `fsoc/load.4th`. Слово копирует листы, консоль и `soc_main.cpp`, пишет `csr.4th` и `csr.json` в переданный каталог, запускает ассемблер в `firmware.hex` и пишет `sim.sh`, вызывает fhdlgen с `FSOC_SOC_TOP` в строке `system`. Проверить, что в `fsoc.4th` нет ветки по имени soc и что в `fsoc/soc.4th` нет пути `build/soc/software`.
- [x] 2.4 Добавить `projects/soc_emul/target.4th`: задача `soc`, таргет `emulation`, `0 0 fsoc-board!`. Проверить, что `git check-ignore -v` не игнорирует этот `target.4th`.

## 3. Проверка и документация

- [x] 3.1 Добавить `tests/soc_test.4th`. Прогнать из `projects/soc_emul` сборку с `FSOC_EMU_UART_BYTES=2` и `FSOC_EMU_FAST=1` и проверить журнал: есть `uart tx o` и следом `uart tx k`, других строк `uart` нет. Проверить, что `firmware.hex` совпадает с выходом ассемблера, в `top.v` нет `j1_prompt`, `csr.4th` содержит `CSR-uart-rxtx`, `csr.json` содержит `uart_rxtx`. Проверить `fsoc --load` в том же каталоге: код 0.
- [x] 3.2 Обновить README, AGENTS.md и doc/roadmap.md: запуск `cd projects/soc_emul && fsoc --build`, `ok` из исполнения прошивки, следующий шаг — сборка и запуск полноценной Forth-системы. Проверить, что README больше не предлагает `targets/base_soc.4th` как способ запуска.
- [x] 3.3 Прогнать `fmix test` и убедиться, что все тесты зелёные, включая прежний `tests/j1_prompt_test.4th`.
