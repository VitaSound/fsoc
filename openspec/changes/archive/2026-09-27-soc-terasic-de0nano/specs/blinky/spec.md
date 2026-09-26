# Spec Delta

## MODIFIED Requirements

### Requirement: Лист остаётся в rtl
Логика blinky MUST жить в `rtl/blinky.v`. Топ MUST генерироваться из `designs/blinky_top.4th` и MUST инстанцировать этот лист. Каталога `tasks/` MUST NOT быть.

#### Scenario: Три проекта с собственными копиями
- **WHEN** собраны `projects/blinky_emul`, `projects/blinky_terasic_de0nano` и `projects/blinky_colorlight_5a_75e_v6_0`
- **THEN** в каждом есть свой `top.v` и копия `blinky.v`, а источник листа по-прежнему `rtl/blinky.v`

### Requirement: Плата задаёт пины, не таргет
Таргет Quartus MUST писать `<project>.qpf` и `.qsf` из переданных ему имени проекта, top, Verilog-файла, такта и карты ресурс→порт, а семейство и устройство MUST брать из загруженной платы. `.qpf` MUST содержать `QUARTUS_VERSION = "11.0"` и `PROJECT_REVISION` с именем проекта. Значение `FAMILY` в `.qsf` MUST быть в кавычках. Каждый файл из `includes.lst` MUST быть `VERILOG_FILE`, а строки `` `include `` MUST быть убраны из топа платы. Эмуляция MUST по-прежнему собирать топ через `` `include ``. Имя blinky и пины `clk50`/`user_led` MUST задавать задача. Для Terasic DE0-Nano `clk` MUST быть PIN_R8, `led` MUST быть PIN_A15, устройство MUST быть `EP4CE22F17C6`. Таргет MUST NOT содержать литерал семейства FPGA.

#### Scenario: qsf двух плат
- **WHEN** задача собрана на `terasic_de0nano` и на `ep2c5_mini`
- **THEN** первый `.qsf` содержит `PIN_A15 -to led`, `DEVICE EP4CE22F17C6` и `FAMILY "Cyclone IV E"`, второй — `FAMILY "Cyclone II"` и `DEVICE EP2C5T144C8`, и ни один `top.v` платы не содержит `LED_BIT`

#### Scenario: qsf третьей платы
- **WHEN** задача собрана на `ep2c5_mini`
- **THEN** `.qsf` содержит `FAMILY "Cyclone II"` и `DEVICE EP2C5T144C8`

#### Scenario: Проект Quartus II 11 и DE0-Nano
- **WHEN** собран `projects/blinky_terasic_de0nano`
- **THEN** `blinky.qpf` содержит `QUARTUS_VERSION = "11.0"` и `PROJECT_REVISION = "blinky"`, `blinky.qsf` содержит `PIN_R8 -to clk`, `PIN_A15 -to led`, `DEVICE EP4CE22F17C6`, `FAMILY "Cyclone IV E"`, `VERILOG_FILE blinky.v` и `VERILOG_FILE top.v`, а `top.v` платы не содержит `` `include ``

### Requirement: Такт blinky берётся с платы
Задача blinky MUST брать единственный такт платы и MUST писать период ограничения из его частоты. На плате 50 МГц период Quartus MUST быть `20.000`, а `.sdc` MUST заканчиваться `derive_clock_uncertainty`. `.qsf` MUST называть этот файл через `SDC_FILE`. На Colorlight 5A-75E V6.0 такт MUST быть 25 МГц: порт `clk` на `P6`, порт `led` на `T6`, частота в LPF MUST быть `25.000 MHz`.

#### Scenario: Период Quartus от 50 МГц
- **WHEN** задача собрана на `terasic_de0nano`
- **THEN** `blinky.sdc` содержит `create_clock -name clk -period 20.000` и `derive_clock_uncertainty`, а `blinky.qsf` содержит `SDC_FILE blinky.sdc`

#### Scenario: LPF Colorlight V6.0
- **WHEN** собран `projects/blinky_colorlight_5a_75e_v6_0` с `FSOC_SYNTH_SKIP=1`
- **THEN** `blinky.lpf` содержит `SITE "P6"`, `SITE "T6"` и `FREQUENCY PORT "clk" 25.000 MHz`
