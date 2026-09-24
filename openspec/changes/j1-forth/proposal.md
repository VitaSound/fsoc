# Proposal

## Why

`projects/soc_emul` уже исполняет образ и печатает два байта `ok`. На этом же ядре J1 существует готовая интерактивная система: SwapForth J1a Джеймса Боумана. Нужен её словарь и её сеанс, а не урезанный набор из десятка слов.

## What Changes

- Образ прошивки — SwapForth для J1a. Ядро собирает Forth-кросс-компилятор `j1a/cross.fs` из `nuc.fs`. Поверх него в тот же образ входят слова из `j1a/swapforth.fs`, `common/core.fs` и `common/core-ext.fs`. `fsoc --build` из `projects/soc_emul` кладёт готовый образ в `firmware.hex` и запускает Verilator. `j1_prompt` источником байт не становится.
- Словарь — тот, с которым эта система выходит в консоль. Это ANS CORE целиком, кроме `environment?`: в исходниках J1a этого слова нет. Сверх ядра ANS в образе есть и слова самой J1a: `io@`, `io!`, `key?`, `words`, `see`, `dump`, `hex` и остальные, которые компилирует `swapforth.fs`. Наборы DOUBLE, FILE, FLOAT и FAT32 из `common/` эта система не подключает.
- Сеанс такой же, как у их оболочки. После сброса передача выдаёт CR и LF. Первый байт приёма ядро снимает и отбрасывает. Дальше строка исполняется, печать слов идёт в передачу, ответ заканчивается пробелом, `ok`, CR и LF.
- **BREAKING** для журнала текущей задачи `soc`: сеанс больше не заканчивается ровно на двух байтах `o` и `k`.

## Capabilities

### New Capabilities

- `soc`: задача SoC на J1 — образ SwapForth J1a, его словарь и его ответ ` ok` на введённую строку. В `openspec/specs/` этой возможности ещё нет.

### Modified Capabilities

- Нет. Требования `builder` и `blinky` не меняются.

## Impact

- В репозиторий кладутся исходники SwapForth J1a (BSD, тот же лицензионный режим, что у уже вендорного `j1.v`): кросс-компилятор, ядро, `swapforth.fs`, `core.fs`, `core-ext.fs`.
- `cpu/j1/j1_wrap.v`: карта памяти и UART как у J1a, порт `uart_rx`, запись RAM.
- `designs/soc_top.4th`: вход `uart_rx`. Каталог проекта, плата и способ запуска не называются.
- `fsoc/soc_main.cpp`: кадр UART, рукопожатие загрузки и строки с stdin или из `FSOC_EMU_UART_IN`.
- `tests/soc_test.4th`, README, AGENTS.md, doc/roadmap.md, CHANGELOG.md.
- Без смены контракта: `emu/con`, билдер, blinky, `j1_prompt` и его тест, плата и Quartus.
