# Design

## Context

Эмуляция — Verilator 4.038, такт ведёт `emu/clock` (полупериод 10 нс). `sim.sh` пишет `targets/emulation.4th` в момент `--build`. `FSOC_*` читается через `getenv` в Gforth и наследуется процессом симуляции; `setenv` не вызывать. В hdl-modules WavePeek — внешний CLI поверх уже снятого VCD (`tools/peek_wave.py`, skill 3.0.1). GTKWave в fsoc не подключается.

`VerilatedVcdC::dump` требует строго растущее время после первого ненулевого штампа. Несколько дампов в момент 0 допустимы.

## Goals / Non-Goals

**Goals:**

- Опциональный `trace.vcd` из смотрового бинаря blinky и soc.
- Запрос к дампу через `wavepeek`, без разбора каталога модулей.
- Прогон без переменной не меняется.

**Non-Goals:**

- GTKWave, FST, трассировка `Vtop_feed`.
- Обязательная установка `wavepeek` в `fmix test`.
- Замена журнала `emu/con`.

## Decisions

1. **Флаг решается при emit.** `emu-sim-sh` читает `FSOC_EMU_TRACE` через `getenv`. Непустое значение вписывает `--trace` и `-DVM_TRACE` только в строку `verilator` для `*_main.cpp`. Строка `*_feed.cpp` остаётся прежней. Так `grep --trace sim.sh` после обычного прогона пуст: флага нет в тексте скрипта, а не только в ветке shell.

2. **`emu/trace` не знает задачу.** `Trace::open(top)` при `VM_TRACE` и непустом env открывает `trace.vcd` (`traceEverOn`, `top->trace`, глубина 99). Без `VM_TRACE` и при непустом env `open` пишет ошибку и возвращает отказ. `dump(t)` после `eval`, `end_cycle` на спаде clk закрывает файл после окна. Окно: 4096 тактов, либо `FSOC_EMU_CYCLES`, если оно больше. `soc_feed.cpp` `Trace` не вызывает; его `trace.cc` собирается заглушкой.

3. **Время дампа — `clk.t` на момент `eval`.** Начальный eval blinky и первый подъём clk оба попадают в t=0; Verilator это принимает. Дальше штампы 10, 20, … не повторяются. Сброс soc дампит t=0 и t=10; следующий штамп даёт уже цикл `Clock::run`.

4. **`tools/peek.sh` из каталога проекта.** Ищет `wavepeek` в `PATH` и `./trace.vcd`, дописывает `--waves`, если его нет в аргументах. Вызов: `"$FSOC_HOME/tools/peek.sh" info`. Skill копируется из hdl-modules (pin 3.0.1).

## Risks / Trade-offs

- [`FSOC_EMU_CYCLES` в сотни тысяч раздувает VCD] → окно по умолчанию 4096; длинный предел удлиняет дамп сознательно. Документировать.
- [Повторный запуск бинаря без пересборки] → env задаётся на `--build`, потому что `--trace` — флаг компиляции. Старый бинарь при внезапном env завершается с ошибкой.
- [Два `dump` в t=0] → проверка Verilator 4: нулевой прошлый штамп не считается нарушением монотонности.

## Migration Plan

1. OpenSpec, затем `emu/trace` и условный `sim.sh`.
2. Крюки в `blinky_main` и `soc_main`.
3. `peek.sh`, skill, документация, тест blinky.

Откат: убрать копирование `trace.*` и крюки; без `FSOC_EMU_TRACE` поведение и так совпадает с прежним.

## Open Questions

Нет.
