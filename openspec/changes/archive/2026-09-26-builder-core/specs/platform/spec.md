# Spec Delta

## Purpose

Platform DSL: файл платы описывает устройство, семейство FPGA, ресурсы с пинами и коннекторы; задача запрашивает ресурсы по имени и индексу, тулчейн читает пины и семейство из запросов.

## ADDED Requirements

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
