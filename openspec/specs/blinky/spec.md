# blinky Specification

## Purpose

Задача blinky: лист Verilog, топ из fhdlgen, три рабочих проекта. Консоль эмуляции печатает события устройства, а не каждый такт.

## Requirements

### Requirement: Дизайн не знает способ запуска
Файл в `designs/` MUST описывать модуль и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий через `FSOC_BLINKY_TOP`. Слой MUST NOT подставлять свой каталог, если путь не передан.

#### Scenario: Топ без каталога эмуляции
- **WHEN** читается `designs/blinky_top.4th`
- **THEN** в файле нет `projects/` и нет `blinky_emul`, а `top.v` пишется только по пути из `FSOC_BLINKY_TOP`

### Requirement: Эмуляция не знает задачу
`emu/` MUST содержать только общую консоль (`con_pin`, `con_uart` и экран строки набора) и MUST NOT содержать `main` задачи. `main` MUST жить рядом с задачей. Сборка эмуляции MUST копировать его в каталог проекта вместе с консолью. Blinky экран строки набора MUST NOT открывать.

#### Scenario: main blinky рядом с задачей
- **WHEN** собрана эмуляция blinky
- **THEN** `main` взят из `fsoc/blinky_main.cpp`, в каталоге проекта есть его копия, а в `emu/` нет файла с именем blinky

### Requirement: Лист остаётся в rtl
Логика blinky MUST жить в `rtl/blinky.v`. Топ MUST генерироваться из `designs/blinky_top.4th` и MUST инстанцировать этот лист. Каталога `tasks/` MUST NOT быть.

#### Scenario: Три проекта с собственными копиями
- **WHEN** собраны `projects/blinky_emul`, `projects/blinky_vitasound_ep4ce10` и `projects/blinky_rz_easyfpga`
- **THEN** в каждом есть свой `top.v` и копия `blinky.v`, а источник листа по-прежнему `rtl/blinky.v`

### Requirement: Эмуляция печатает смену led
Эмуляция MUST идти на Verilator с тактом 50 МГц. Консоль MUST печатать строку `t=<ns> pin led <значение>` только при смене уровня, включая первое значение. Каждый такт MUST NOT печататься. Просмотр MUST идти до Ctrl+C. `LED_BIT` по умолчанию MUST быть 25.

#### Scenario: Короткий делитель в тесте
- **WHEN** тест задаёт `LED_BIT` 4 и `FSOC_EMU_EDGES=2` с `FSOC_EMU_FAST=1`
- **THEN** в журнале есть строки `pin led 0` и `pin led 1`, и число строк `pin led` не больше 8

### Requirement: Плата задаёт пины, не таргет
Таргет Quartus MUST писать `.qsf` из переданных ему имени проекта, top, Verilog-файла, такта и карты ресурс→порт. Имя blinky и пины `clk50`/`user_led` MUST задавать задача. Для VitaSound `clk` MUST быть PIN_23, `led` MUST быть PIN_86. Для RZ-EasyFPGA `led` MUST быть PIN_87.

#### Scenario: qsf двух плат
- **WHEN** задача собрана на `vitasound_ep4ce10` и на `rz_easyfpga`
- **THEN** первый `.qsf` содержит `PIN_86 -to led` и `DEVICE EP4CE10E22C8`, второй — `PIN_87 -to led` и `DEVICE EP4CE6E22C8`, и ни один `top.v` платы не содержит `LED_BIT`

### Requirement: Канал uart того же вида
Канал UART MUST оставаться в общей консоли рядом с `con_pin`. В виде `log` декодированный байт MUST печататься строкой `t=<ns> uart <имя> <байт>`. Blinky этот канал MUST NOT вызывать и экран строки набора MUST NOT открывать. Строки `pin` MUST печататься по-прежнему: `t=<ns> pin led <значение>` только при смене уровня.

#### Scenario: Байт ещё не подключён
- **WHEN** идёт эмуляция blinky
- **THEN** в консоли нет строк `uart`

#### Scenario: Журнал led на месте
- **WHEN** тест задаёт `LED_BIT` 4 и `FSOC_EMU_EDGES=2` с `FSOC_EMU_FAST=1`
- **THEN** в журнале есть строки `pin led 0` и `pin led 1`
