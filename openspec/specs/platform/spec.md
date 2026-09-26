# platform Specification

## Purpose

Platform DSL: файл платы описывает устройство, семейство FPGA, ресурсы с пинами и коннекторы; задача запрашивает ресурсы по имени и индексу, тулчейн читает пины и семейство из запросов.

## Requirements

### Requirement: Плата описывает себя
Файл `boards/<имя>.4th` MUST начинаться с `s" <имя>" platform-new`, MUST задать `plat-device` и `plat-family`. Ресурс MUST описываться блоком `s" <имя>" <индекс> io-begin … io-end` со словами `pins`, `iostd`, `misc`, `subsignal`. Файл платы MUST NOT называть задачу, проект или тулчейн.

#### Scenario: Три платы загружаются
- **WHEN** по очереди загружены `vitasound_ep4ce10`, `rz_easyfpga`, `ep2c5_mini`
- **THEN** `plat.name@`, `plat.device@` и `plat.family@` возвращают `vitasound_ep4ce10` / `EP4CE10E22C8` / `Cyclone IV E`, `rz_easyfpga` / `EP4CE6E22C8` / `Cyclone IV E`, `ep2c5_mini` / `EP2C5T144C8` / `Cyclone II`

#### Scenario: Плата не знает задачу
- **WHEN** читается любой файл `boards/*.4th`
- **THEN** в нём нет `request`, `quartus-`, `projects/` и имён задач

### Requirement: Запрос ресурса
`s" <имя>" <индекс> request` MUST найти ресурс платы и добавить его в список запросов. Неизвестный ресурс MUST останавливать с `request: unknown resource`. `request-all` MUST запросить все индексы ресурса. `io-find` MUST вернуть ресурс или 0. Стек после `request` и после `included` файла платы MUST быть в том же состоянии, что до них.

#### Scenario: Запрос clk50 и user_led
- **WHEN** загружена `vitasound_ep4ce10` и выполнены `s" clk50" 0 request` и `s" user_led" 0 request`
- **THEN** `plat.reqs-len` равен 2, `s" nosuch" 0 io-find` равен 0, а глубина стека равна глубине до загрузки платы

### Requirement: Семейство приходит из платы в тулчейн
Файл `.qsf` MUST содержать `FAMILY` из `plat.family@` и `DEVICE` из `plat.device@`. Тулчейн MUST NOT содержать литерал семейства. Плата без семейства MUST останавливать запись `.qsf`.

#### Scenario: Cyclone II для ep2c5_mini
- **WHEN** blinky собран на плате `ep2c5_mini`
- **THEN** `blinky.qsf` содержит `FAMILY Cyclone II` и `DEVICE EP2C5T144C8`, а в `targets/quartus.4th` нет строки `Cyclone`

### Requirement: Тактовый ресурс знает частоту
Внутри блока `io-begin … io-end` тактового ресурса плата MUST задавать `plat-clock-hz ( hz -- )`. `io.clock-hz@ ( io -- hz )` MUST возвращать это значение; для ресурса без частоты — 0. Задача, запросившая тактовый ресурс без частоты, MUST остановиться с `clock resource has no frequency`.

#### Scenario: clk50 трёх плат
- **WHEN** загружена любая из `vitasound_ep4ce10`, `rz_easyfpga`, `ep2c5_mini` и найден `s" clk50" 0 io-find`
- **THEN** `io.clock-hz@` равно 50000000

### Requirement: Пин подсигнала в карту тулчейна
`quartus-map-sub ( res index sub port -- )` MUST взять пин из `subsignal` ресурса и записать `set_location_assignment PIN_<пин> -to <порт>`. Отсутствующий подсигнал MUST останавливать с `quartus-map-sub: missing subsignal`.

#### Scenario: serial tx и rx
- **WHEN** загружена `vitasound_ep4ce10`, выполнены `s" serial" 0 request`, `s" serial" 0 s" tx" s" uart_tx" quartus-map-sub`, `s" serial" 0 s" rx" s" uart_rx" quartus-map-sub`
- **THEN** записанный `.qsf` содержит `PIN_114 -to uart_tx` и `PIN_115 -to uart_rx`

### Requirement: Активный низкий выход
Слово `active-low` внутри `io-begin … io-end` MUST выставить флаг ресурса. `io.low@ ( io -- flag )` MUST вернуть его. Ресурс без этого слова MUST иметь флаг 0. Задача SoC на плате с этим флагом у `user_led` MUST передать генератору `LED_LOW=1`.

#### Scenario: Colorlight и VitaSound
- **WHEN** загружены `vitasound_ep4ce10` и по очереди `colorlight_5a_75e_v6_0`, `colorlight_5a_75e_v7_1`, `colorlight_5a_75e_v8_2`, и у каждой взят `s" user_led" 0 io-find`
- **THEN** у VitaSound `io.low@` равен 0, а у трёх Colorlight `io.low@` не равен 0
