# Spec Delta

## Purpose

Задача SoC: ядро J1 исполняет образ, собранный Forth-ассемблером, и эмуляция печатает `ok` из этого исполнения.

## ADDED Requirements

### Requirement: Дизайн не знает способ запуска
Файл в `designs/` MUST описывать модуль SoC и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий через `FSOC_SOC_TOP`. Слой MUST NOT подставлять свой каталог, если путь не передан.

#### Scenario: Топ без каталога эмуляции
- **WHEN** читается `designs/soc_top.4th`
- **THEN** в файле нет `projects/` и нет `soc_emul`, а `top.v` пишется только по пути из `FSOC_SOC_TOP`

### Requirement: ok даёт исполнение прошивки
Прошивка MUST быть исходником Forth-ассемблера J1. Сборка MUST прогнать этот ассемблер и загрузить получившийся образ в память J1. Ядро MUST исполнить образ. Байты `ok` MUST появиться из этого исполнения. Модуль `j1_prompt` MUST NOT быть источником этих байт. Каталога `tasks/` MUST NOT быть. Полноценная Forth-система в это изменение MUST NOT входить.

#### Scenario: Образ ассемблера, не заглушка
- **WHEN** собрана эмуляция SoC
- **THEN** `firmware.hex` в каталоге проекта совпадает с выходом Forth-ассемблера, в `top.v` нет `j1_prompt`, а исходник прошивки остаётся Forth-текстом ассемблера

### Requirement: main SoC не лежит в emu
`emu/` MUST содержать только общую консоль и MUST NOT содержать `main` задачи SoC. `main` MUST жить рядом с задачей. Сборка эмуляции MUST копировать его в каталог проекта вместе с консолью.

#### Scenario: main рядом с задачей
- **WHEN** собрана эмуляция SoC
- **THEN** `main` взят из `fsoc/soc_main.cpp`, в каталоге проекта есть его копия, а в `emu/` нет файла с именем soc

### Requirement: CSR пишется в каталог проекта
Сборка MUST выгрузить карту ctrl, uart, gpio и timer в `csr.4th` и `csr.json` того каталога, откуда запущен билдер. Билдер MUST NOT писать эту карту в `build/soc/software`.

#### Scenario: Имена регистров UART
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** в этом каталоге `csr.4th` содержит `CSR-uart-rxtx`, а `csr.json` содержит `uart_rxtx`

### Requirement: Эмуляция печатает ok
Эмуляция MUST идти на Verilator с тактом 50 МГц до Ctrl+C. После сброса исполнение прошивки MUST передать по UART сначала `o`, затем `k`. Консоль MUST напечатать строки `t=<ns> uart tx o` и `t=<ns> uart tx k` в этом порядке, по одному разу. Каждый такт MUST NOT печататься.

#### Scenario: Два байта в тесте
- **WHEN** тест задаёт `FSOC_EMU_UART_BYTES=2` и `FSOC_EMU_FAST=1`
- **THEN** в журнале есть `uart tx o` и следом `uart tx k`, и других строк `uart` нет

### Requirement: Запуск как у blinky
Идентичность проекта MUST читаться из `target.4th`: задача `soc`, таргет `emulation`, плата не задана. `fsoc --build` MUST породить `top.v`, `firmware.hex`, `csr.4th`, `csr.json` и `sim.sh`, затем запустить просмотр. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Сборка из каталога проекта
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** появляются `top.v`, `firmware.hex`, `sim.sh`, `csr.4th` и `csr.json`, Verilator компилируется и просмотр идёт до Ctrl+C
