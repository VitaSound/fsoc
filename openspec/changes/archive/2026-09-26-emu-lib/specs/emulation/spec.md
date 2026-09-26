# Spec Delta

## Purpose

Библиотека эмуляции в `emu/` даёт задачам такт, UART-кодек, скрипт сеанса и коды выхода; она не знает задачу, текст прошивки и иерархию дизайна.

## ADDED Requirements

### Requirement: Библиотека не знает задачу
Файлы `emu/` MUST NOT содержать имена задач, текст прошивки, имена сигналов из иерархии дизайна (`top__DOT__`) и литералы адресов шины. Такт (50 МГц, полупериод 10 нс), realtime-пауза, обработка Ctrl+C и предел `FSOC_EMU_CYCLES` MUST жить в библиотеке. `main` задачи MUST только соединить порты `Vtop` с библиотекой.

#### Scenario: Чистый emu
- **WHEN** выполняется `rg "lamp|blinky|soc_|top__DOT__|0x400|0x800" emu/`
- **THEN** совпадений нет

#### Scenario: Один цикл тактов
- **WHEN** читаются `fsoc/tasks/blinky_main.cpp` и `fsoc/tasks/soc_main.cpp`
- **THEN** ни один не содержит `std::this_thread::sleep_until`, `std::signal` и собственного цикла `while (!g_stop)`

### Requirement: UART-кодек с делителем-параметром
Приём и передача 8N1 MUST быть словами библиотеки с делителем такта на бит как параметром. Значение делителя MUST приходить из одного места сборки и MUST совпадать с делителем обёртки J1. Литерал `104` MUST NOT стоять в `main` задачи.

#### Scenario: Делитель из сборки
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN=1 2 + .`
- **THEN** `sim.sh` передаёт делитель компилятору одним флагом, тот же делитель стоит параметром инстанса обёртки в `top.v`, и журнал содержит `3` и ` ok`

### Requirement: Скрипт сеанса
Сеанс MUST ждать CR LF после сброса, послать один CR, затем отдавать строки из `FSOC_EMU_UART_IN` (LF делит строки) или из stdin / панели. Конец ответа — ` ok` CR LF либо `?` с паузой приёма. Со скриптом сеанс MUST завершиться после последнего ответа. Без скрипта сеанс MUST идти до Ctrl+C или до `FSOC_EMU_CYCLES`.

#### Scenario: Скрипт из двух строк
- **WHEN** `FSOC_EMU_UART_IN` содержит `: DOUBLE DUP + ;` и `21 DOUBLE .`
- **THEN** журнал содержит `4`, `2`, ` ok`, процесс завершился с кодом 0

#### Scenario: Предел тактов без скрипта
- **WHEN** в `projects/soc_blink` запущен `./obj_dir/Vtop` с `FSOC_EMU_FAST=1`, `FSOC_EMU_CON=pin` и `FSOC_EMU_CYCLES=200000`
- **THEN** процесс завершился с кодом 0, журнал содержит `pin led 1` и `pin led 0`, а в `main` нет поиска текста лампы

### Requirement: Коды выхода
Код 0 MUST означать: скрипт выполнен, или предел `FSOC_EMU_CYCLES` / `FSOC_EMU_EDGES` / `FSOC_EMU_UART_BYTES` достигнут. Код 1 MUST означать: скрипт не завершён до предела. Код 130 MUST означать Ctrl+C. Билдер MUST считать 130 нормальным завершением просмотра.

#### Scenario: Незавершённый скрипт
- **WHEN** `FSOC_EMU_UART_IN=NOWORD` и `FSOC_EMU_CYCLES=1000`
- **THEN** код выхода 1

### Requirement: Шаг прошивки отделён от просмотра
Образ прошивки MUST собирать отдельный исполняемый файл `feed`: вход — плоский Forth-файл без `include`, выход — `firmware.hex` на 4096 слов, записанный самой обёрткой по сигналу `dump`. `main` просмотра MUST NOT читать файлы прошивки и MUST NOT писать `firmware.hex`. Раскрытие `include` MUST делать билдер до запуска `feed`.

#### Scenario: Снимок из Verilog
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** `firmware.hex` содержит 4096 строк, отличается от `nuc.hex`, в `fsoc/tasks/soc_main.cpp` нет `fopen("firmware.hex"`, а в `cpu/j1/j1_wrap.v` есть `$writememh`

#### Scenario: Плоский файл подачи
- **WHEN** билдер подготовил файл подачи для `swapforth.fs`
- **THEN** в этом файле нет строк, начинающихся с `include`, и он содержит текст `core.fs` и `core-ext.fs`
