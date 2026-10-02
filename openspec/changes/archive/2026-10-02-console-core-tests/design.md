# Design

## Context

Три консоли fsys: j1a (kernel + common + core), j1b (то же + extra), avr (kernel + extra-min). SwapForth не входит. `accept` на всех трёх только эхоит байт в TIB.

## Goals / Non-Goals

**Goals:**

- BS (8) и DEL (127) укорачивают строку и шлют `BS SPACE BS`; пустая строка не уходит в минус.
- Один текстовый транскрипт (`FSOC_EMU_CON=term` / stdout avr-con) и один набор сценариев ядра.
- Эталон `words` — ключи JSON word-graph, не список ANS CORE из `soc_uart.py`.
- Каждое имя JSON имеет тег `run` / `colon` / `skip` с причиной.

**Non-Goals:**

- Образы SwapForth, `extra-min=1` на j1a как четвёртый таргет.
- Поведенческий вызов `branch0`, `key`, `quit` и прочих внутренностей.
- Один прогон Verilator на каждое слово.

## Decisions

1. Правка `accept` копируется по смыслу в три fasm-текста; общего исходника ядра нет.
2. Сеанс ядра пишет `uart.in` байтами (включая 8) и подаёт его в emu или `avr-con -f`.
3. AVR JSON собирает тот же `build.py` из kernel + extra-min.
4. `common_test` остаётся глубоким прогоном common; `con_core` — короткий общий REPL.

## Risks / Trade-offs

- Длинный поведенческий скрипт j1 требует большой `FSOC_EMU_CYCLES`; один сеанс на id, не 262 прогона.
- AVR без `fsys/common`: универсальный `words` проверяет только пересечение (~60 имён).
