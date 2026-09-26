# Spec Delta

## MODIFIED Requirements

### Requirement: main SoC не лежит в emu
`emu/` MUST содержать только общую библиотеку эмуляции и MUST NOT содержать `main` задачи SoC. `main` MUST жить рядом с задачей в `fsoc/tasks/` и MUST соединять порты `Vtop` со словами библиотеки, не повторяя цикл тактов и UART-кодек. Сборка эмуляции MUST копировать его в каталог проекта вместе с библиотекой.

#### Scenario: main рядом с задачей
- **WHEN** собрана эмуляция SoC
- **THEN** `main` взят из `fsoc/tasks/soc_main.cpp`, в каталоге проекта есть его копия и копии `emu/*.cc`, а в `emu/` нет файла с именем soc

### Requirement: Запуск сеанса
Без заданной строки ввода `fsoc --build` MUST запустить Verilator до Ctrl+C или до `FSOC_EMU_CYCLES` и MUST читать следующие строки с stdin или с панели. Со строкой ввода из `FSOC_EMU_UART_IN` и с `FSOC_EMU_FAST=1` прогон MUST завершиться с кодом 0 после последнего ответа ` ok` и с кодом 1, если ответ не пришёл до предела. Просмотр MUST NOT завершаться по содержимому байтов UART или по числу переключений пина. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Скриптованная строка заканчивает тест
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** код возврата 0, а журнал содержит байт `3` и ответ ` ok`

#### Scenario: Blink завершается по пределу
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build` с `FSOC_EMU_FAST=1`, `FSOC_EMU_CON=term` и `FSOC_EMU_CYCLES=200000`
- **THEN** код возврата 0, вывод содержит `lamp on` и `lamp off` и не содержит ` ok`

## ADDED Requirements

### Requirement: Образ прошивки собирает отдельный шаг
`firmware.hex` MUST создавать шаг `feed`, отделённый от интерактивного просмотра: билдер MUST подготовить плоский файл подачи (раскрыв `include` SwapForth), запустить `feed` и получить `firmware.hex` из обёртки. Переменная `FSOC_EMU_SNAPSHOT` MUST NOT использоваться. Интерактивный просмотр MUST только загрузить готовый `firmware.hex`.

#### Scenario: Сборка образа без интерактивного main
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build`
- **THEN** в каталоге появляются плоский файл подачи, `obj_dir/Vtop_feed` и `firmware.hex` на 4096 строк, а `rg FSOC_EMU_SNAPSHOT fsoc/ emu/ targets/` пусто
