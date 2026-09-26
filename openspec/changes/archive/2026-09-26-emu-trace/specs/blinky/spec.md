# Spec Delta

## ADDED Requirements

### Requirement: Опциональный VCD эмуляции
Без `FSOC_EMU_TRACE` `sim.sh` MUST NOT содержать `--trace` и прогон MUST NOT создавать `trace.vcd`. С непустым `FSOC_EMU_TRACE` сборка смотрового бинаря (`*_main.cpp`) MUST передать Verilator `--trace` и `-DVM_TRACE`, а сборка `*_feed.cpp` MUST NOT получать `--trace`. Прогон MUST записать непустой `trace.vcd` в каталог проекта и MUST по-прежнему печатать смену `led`. Окно записи MUST быть не короче 4096 тактов и MUST удлиняться до `FSOC_EMU_CYCLES`, если этот предел больше. Бинарь, собранный без `--trace`, при заданном `FSOC_EMU_TRACE` MUST завершиться с ошибкой. `wavepeek` MUST NOT быть обязательным для прохождения тестов.

#### Scenario: Прогон без дампа
- **WHEN** эмуляция blinky запускается с `FSOC_EMU_EDGES=2` и `FSOC_EMU_FAST=1`, а `FSOC_EMU_TRACE` не задана
- **THEN** код выхода 0, журнал содержит `pin led 0` и `pin led 1`, в `sim.sh` нет `--trace`, файла `trace.vcd` нет

#### Scenario: Короткий дамп blinky
- **WHEN** эмуляция blinky запускается с `FSOC_EMU_TRACE=1`, `FSOC_EMU_EDGES=2` и `FSOC_EMU_FAST=1`
- **THEN** код выхода 0, журнал содержит `pin led 0` и `pin led 1`, в `sim.sh` ровно одно `--trace` (строка feed его не содержит), `trace.vcd` непустой
