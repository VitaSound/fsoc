# Proposal

## Why

Консоль fsys на j1a, j1b и avr проверяется разными драйверами и разными кусками сценария. Стирания в `accept` нет ни на одном из трёх id. Словарь `words` сверяется не целиком.

## What Changes

- Одна семантика BS/DEL в `accept` kernel j1a, j1b и avr.
- Общий сеанс `sys: fsys`: ввод, стирание, неизвестное слово, стек, `+`, `.s`, `:`, пересечение `words`.
- Полный `words` против JSON образа (`fsys-j1a`, `fsys-j1b`, новый `fsys-avr-extra-min`).
- Поведение публичных и compile-only слов; внутренности компилятора только в `words`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `fsys`: стирание в трёх kernel; универсальный REPL; эталон словаря extra-min AVR.

## Impact

- `fsys/kernel/j1a/kernel.4th`, `fsys/kernel/j1b/kernel.4th`, `fsys/kernel/avr/kernel.4th`
- `tests/con_session.4th`, `tests/con_core_test.4th`, `tests/con_words.py`
- `doc/j1-word-graph/build.py`, `doc/j1-word-graph/fsys-avr-extra-min.json`
- `tools/avr-con.c` — подача строк из файла
- SwapForth и `soc_uart.py` не вызываются
- Сопровождение: `fmix test` / `gforth tests/con_core_test.4th`; новый fsys-id обязан войти в эту сетку (`AGENTS.md`, README Adding a CPU, `add-cpu-target`, `fsoc-cpu-target.mdc`, спеки `fsys` и `forth-cross`)
