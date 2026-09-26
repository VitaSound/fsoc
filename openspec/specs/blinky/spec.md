# blinky Specification

## Purpose

Задача blinky: лист Verilog, топ из fhdlgen, рабочие проекты эмуляции, Quartus и Yosys. Консоль эмуляции печатает события устройства, а не каждый такт.

## Requirements

### Requirement: Дизайн не знает способ запуска
Файл в `designs/` MUST описывать модуль и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий аргументом генератора `--out`. Дизайн MUST NOT читать переменные окружения. Слой MUST NOT подставлять свой каталог, если путь не передан.

#### Scenario: Топ без каталога эмуляции
- **WHEN** читается `designs/blinky_top.4th`
- **THEN** в файле нет `projects/`, нет `blinky_emul`, нет `getenv`, а `top.v` пишется только в каталог из `--out`

### Requirement: Эмуляция не знает задачу
`emu/` MUST содержать только общую библиотеку эмуляции (консоль `con_pin` / `con_uart` с экраном строки набора, такт, UART-кодек, скрипт сеанса) и MUST NOT содержать `main` задачи. `main` MUST жить рядом с задачей и MUST соединять порты `Vtop` со словами библиотеки, не повторяя цикл тактов. Сборка эмуляции MUST копировать `main` в каталог проекта вместе с библиотекой. Blinky экран строки набора MUST NOT открывать.

#### Scenario: main blinky рядом с задачей
- **WHEN** собрана эмуляция blinky
- **THEN** `main` взят из `fsoc/tasks/blinky_main.cpp`, в каталоге проекта есть его копия и копии `emu/*.cc`, в `emu/` нет файла с именем blinky, а в `blinky_main.cpp` нет `sleep_until` и `std::signal`

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
Таргет Quartus MUST писать `.qsf` из переданных ему имени проекта, top, Verilog-файла, такта и карты ресурс→порт, а семейство и устройство MUST брать из загруженной платы. Имя blinky и пины `clk50`/`user_led` MUST задавать задача. Для VitaSound `clk` MUST быть PIN_23, `led` MUST быть PIN_86. Для RZ-EasyFPGA `led` MUST быть PIN_87. Таргет MUST NOT содержать литерал семейства FPGA.

#### Scenario: qsf двух плат
- **WHEN** задача собрана на `vitasound_ep4ce10` и на `rz_easyfpga`
- **THEN** первый `.qsf` содержит `PIN_86 -to led`, `DEVICE EP4CE10E22C8` и `FAMILY Cyclone IV E`, второй — `PIN_87 -to led`, `DEVICE EP4CE6E22C8` и `FAMILY Cyclone IV E`, и ни один `top.v` платы не содержит `LED_BIT`

#### Scenario: qsf третьей платы
- **WHEN** задача собрана на `ep2c5_mini`
- **THEN** `.qsf` содержит `FAMILY Cyclone II` и `DEVICE EP2C5T144C8`

### Requirement: Такт blinky берётся с платы
Задача blinky MUST брать единственный такт платы и MUST писать период ограничения из его частоты. На плате 50 МГц период Quartus MUST быть `20.000`. На Colorlight 5A-75E V6.0 такт MUST быть 25 МГц: порт `clk` на `P6`, порт `led` на `T6`, частота в LPF MUST быть `25.000 MHz`.

#### Scenario: Период Quartus от 50 МГц
- **WHEN** задача собрана на `vitasound_ep4ce10`
- **THEN** `blinky.sdc` содержит `create_clock -name clk -period 20.000`

#### Scenario: LPF Colorlight V6.0
- **WHEN** собран `projects/blinky_colorlight_5a_75e_v6_0` с `FSOC_SYNTH_SKIP=1`
- **THEN** `blinky.lpf` содержит `SITE "P6"`, `SITE "T6"` и `FREQUENCY PORT "clk" 25.000 MHz`

### Requirement: Канал uart того же вида
Канал UART MUST оставаться в общей консоли рядом с `con_pin`. В виде `log` декодированный байт MUST печататься строкой `t=<ns> uart <имя> <байт>`. Blinky этот канал MUST NOT вызывать и экран строки набора MUST NOT открывать. Строки `pin` MUST печататься по-прежнему: `t=<ns> pin led <значение>` только при смене уровня.

#### Scenario: Байт ещё не подключён
- **WHEN** идёт эмуляция blinky
- **THEN** в консоли нет строк `uart`

#### Scenario: Журнал led на месте
- **WHEN** тест задаёт `LED_BIT` 4 и `FSOC_EMU_EDGES=2` с `FSOC_EMU_FAST=1`
- **THEN** в журнале есть строки `pin led 0` и `pin led 1`

### Requirement: Опциональный VCD эмуляции
Без `FSOC_EMU_TRACE` `sim.sh` MUST NOT содержать `--trace` и прогон MUST NOT создавать `trace.vcd`. С непустым `FSOC_EMU_TRACE` сборка смотрового бинаря (`*_main.cpp`) MUST передать Verilator `--trace` и `-DVM_TRACE`, а сборка `*_feed.cpp` MUST NOT получать `--trace`. Прогон MUST записать непустой `trace.vcd` в каталог проекта и MUST по-прежнему печатать смену `led`. Окно записи MUST быть не короче 4096 тактов и MUST удлиняться до `FSOC_EMU_CYCLES`, если этот предел больше. Бинарь, собранный без `--trace`, при заданном `FSOC_EMU_TRACE` MUST завершиться с ошибкой. `wavepeek` MUST NOT быть обязательным для прохождения тестов.

#### Scenario: Прогон без дампа
- **WHEN** эмуляция blinky запускается с `FSOC_EMU_EDGES=2` и `FSOC_EMU_FAST=1`, а `FSOC_EMU_TRACE` не задана
- **THEN** код выхода 0, журнал содержит `pin led 0` и `pin led 1`, в `sim.sh` нет `--trace`, файла `trace.vcd` нет

#### Scenario: Короткий дамп blinky
- **WHEN** эмуляция blinky запускается с `FSOC_EMU_TRACE=1`, `FSOC_EMU_EDGES=2` и `FSOC_EMU_FAST=1`
- **THEN** код выхода 0, журнал содержит `pin led 0` и `pin led 1`, в `sim.sh` ровно одно `--trace` (строка feed его не содержит), `trace.vcd` непустой
