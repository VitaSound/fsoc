# Design

## Context

Слои уже разведены в коде: `rtl/blinky.v`, `designs/blinky_top.4th`, `boards/*.4th`, `targets/emulation.4th` (только `sim.sh`), `targets/quartus.4th` (только файлы проекта), `emu/con` для строк консоли, рабочие копии в `projects/`. См. proposal.md — Why. Билдер пока сидит в `fsoc.4th` как ветки `blinky` и `soc` и уходит в корень через `bin/fsoc`.

## Goals / Non-Goals

**Goals:**

- Запуск из каталога проекта флагами `--build` и `--load`.
- `target.4th` — единственное место, где названы задача и плата этого проекта.
- Эмуляция по `--build` сама стартует реалтайм, как `litex_sim`.

**Non-Goals:**

- Запуск Quartus (`quartus_map` и далее).
- Проект `blinky_ep2c5_mini` (в `.qsf` семейство всё ещё Cyclone IV E).
- Переименование `targets/base_soc.4th`.
- Каталог `tasks/`.
- Вынос `fsoc soc` в этот билдер.

## Decisions

- Каталог проекта — cwd. `bin/fsoc` больше не делает `cd $FSOC_HOME`; библиотека ищется по `FSOC_HOME`.
- `target.4th` коммитится. Остальное в `projects/` остаётся в `.gitignore`. Имя каталога (`blinky_emul`, `blinky_<board>`) — имя решения; внутри файлы могут повторяться.
- Диспетчер собирает имя слова из поля task (`<task>-emit-emulation` или `<task>-on-board`) и передаёт каталог `.`. Ветки `if blinky` в `fsoc.4th` нет.
- `--build` затем `--load`, если заданы оба. На эмуляции `--load` — пустая операция с кодом 0.
- Эмуляционный `--build` вызывает тот же прогон, что `sim.sh`: компиляция и `Vtop` до Ctrl+C. Тесты по-прежнему режут прогон через `FSOC_EMU_EDGES` и `FSOC_EMU_FAST`.
- Путь проекта не склеивается в билдере сдвигом символов. Раньше префикс `../projects/blinky_` длиной 19 писался со смещением 18, `_` затирался, появлялись `blinkyvitasound_ep4ce10` и `blinkyrz_easyfpga`.

## Risks / Trade-offs

- [Quartus не установлен, `--load` падает на `quartus_pgm`] → это поведение `load.sh`, билдер его не прячет.
- [`projects/` в gitignore спрячет и `target.4th`] → явные исключения в `.gitignore`.
- [Тест гоняет бесконечный `--build`] → тесты зовут слова задачи с `FSOC_EMU_EDGES`, не интерактивный билдер.

## Migration Plan

- Добавить три `target.4th`, поправить лаунчер и `fsoc.4th`, обновить README / AGENTS / roadmap.
- Старые команды `fsoc blinky` и `fsoc blinky <board>` не поддерживать.
- Откат: вернуть `cd` в лаунчере и ветки в `fsoc.4th`.
