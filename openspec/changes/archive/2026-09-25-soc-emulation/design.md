# Design

## Context

Слои blinky уже разведены: лист Verilog, топ из fhdlgen, `targets/emulation.4th` пишет только `sim.sh`, `emu/con` печатает события, `main` задачи лежит рядом с задачей, билдер вызывает `<task>-emit-emulation` из `target.4th`. См. proposal.md — Why. `cpu/j1/j1_wrap.v` держит RAM и `$readmemh("firmware.hex")`, но вместо ядра инстанцирует `j1_prompt`. `firmware/hex2readmem.4th` уже переводит hex-слова в строки `$readmemh`. `sim.sh` компилирует один `top.v`; остальные `.v` попадают в сборку только через `` `include ``.

## Goals / Non-Goals

**Goals:**

- Forth-ассемблер J1 собирает прошивку, ядро исполняет образ, в консоли `ok`.
- Задача `soc` повторяет слои blinky и не называет плату.
- Топ инстанцирует лист, а не вбирает его текст.

**Non-Goals:**

- Полноценная Forth-система: компилятор, словарь, интерактивный ввод. Это следующее изменение.
- `j1_prompt` как источник `ok` в задаче `soc`.
- Verilog регистров CSR. Карта остаётся текстом `csr.4th` / `csr.json`.
- Плата iCE40, `SB_IO`, `SB_PLL` и прочий вендорный топ swapforth.
- Проект платы Quartus и правка `targets/quartus.4th`.
- Удаление `targets/base_soc.4th`, `tests/csr_test.4th` и `tests/j1_prompt_test.4th`.
- Правка строки компиляции в `targets/emulation.4th`.

## Decisions

- Ядро и UART берутся из swapforth (BSD-3-Clause): переносимые `j1` и `buart`, не топ iCEStick. `j1_wrap` соединяет их с RAM. Образ — `$readmemh("firmware.hex")`. Запись байта — `io!` в порт с битом 12 (`h# 1000`), готовность передатчика — чтение порта с битом 13 (`h# 2000`), младший бит этого чтения равен «не занят». `j1_prompt` в обёртке нет.
- Ассемблер — Gforth в `firmware/`: те же поля команды, что у swapforth (`imm`, `alu`, `io!`). Исходник прошивки на этом ассемблере ждёт свободный UART и посылает `o`, затем `k`. Выход ассемблера — hex-слова; `hex2readmem` пишет `firmware.hex`. Сборка вызывает эту цепочку и не подставляет константу `0000`.
- `designs/soc_top.4th` описывает `top` с портами `clk`, `rst`, `uart_tx` и инстанцирует `j1_wrap`. Листы ядра и UART подключены `` `include `` из `top.v`. `uart_rx` привязан к 1. Путь выхода — `FSOC_SOC_TOP` в строке `system`, не `setenv`. fhdlgen: `${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen`. Каталог — через `get-dir` и `fsoc-append`.
- Слово задачи — `soc-emit-emulation` в `fsoc/soc.4th`, его подключает `fsoc/load.4th`. В `fsoc.4th` ветки `soc` нет. Слово копирует листы, консоль и `fsoc/soc_main.cpp`, пишет CSR через `cores-minimal-soc` в каталог проекта, запускает ассемблер и `sim.sh`.
- `soc_main.cpp` тактует `top` с полупериодом 10 нс до Ctrl+C. `rst` держится один полный такт, затем снимается. Декодер — 8N1 по проводу `uart_tx`: длительность бита берётся из стартового бита, потому что `buart` не отдаёт бит за такт. Готовый байт уходит в `con_uart("tx", ...)`. Пауза по стенным часам — на байте. `FSOC_EMU_UART_BYTES` обрывает прогон после N байт; `FSOC_EMU_FAST=1` не ждёт стенные часы.
- `projects/soc_emul/target.4th`: задача `soc`, таргет `emulation`, `0 0 fsoc-board!`. Плата не грузится. Исключение `.gitignore` для `projects/*/target.4th` уже есть.

## Risks / Trade-offs

- [Делитель `buart` на 50 МГц растягивает бит] → тест идёт с `FSOC_EMU_FAST=1` и обрывается на двух байтах.
- [Декодер берёт середину бита не там] → мерить период по стартовому биту принятого кадра, не копировать один бит на такт из `tb_prompt.v`.
- [Порт UART не совпал с ядром] → писать бит 12 и читать бит 13, как в карте swapforth, и проверить это исполнением, не отдельной заглушкой.
- [`sim.sh` видит только `top.v`] → ядро и UART только через `` `include ``.
- [`targets/base_soc.4th` всё ещё пишет `build/soc/software`] → README больше не предлагает его как запуск.

## Migration Plan

- Добавить ассемблер, ядро, обёртку, топ, `main`, `projects/soc_emul/target.4th` и тест. Обновить README, AGENTS.md, doc/roadmap.md: сейчас `ok` из прошивки, следующим шагом — полноценная Forth-система.
- `tests/j1_prompt_test.4th` оставить. Задача `soc` этот модуль не собирает.
- Откат: убрать include слова задачи и каталог `projects/soc_emul`. Blinky и библиотека CSR от нового слова не зависят.
