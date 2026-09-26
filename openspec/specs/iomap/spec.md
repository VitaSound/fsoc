# iomap Specification

## Purpose

Карта адресов шины `io` J1 описана один раз в Forth и экспортируется для обёртки Verilog, для прошивки и для хоста; три экспорта согласованы между собой и с железом.

## Requirements

### Requirement: Одна карта устройств
Карта MUST задаваться словами `s" <имя>" <бит> <ширина> <доступ> io-dev` в одном файле. Для SoC этого репозитория карта MUST содержать `led` бит 10 ширина 1 `rw`, `timer` бит 11 ширина 16 `rw`, `uart_data` бит 12 ширина 8 `rw`, `uart_status` бит 13 ширина 2 `ro`. Два устройства MUST NOT занимать один бит.

#### Scenario: Дубль бита
- **WHEN** карта получает второе устройство на бит 10
- **THEN** загрузка останавливается с `io-dev: bit taken`

### Requirement: Три экспорта из карты
Сборка SoC MUST записать в каталог проекта `csr.fs` со строками вида `$400 constant IO-LED` (имя в верхнем регистре, `_` → `-`), `iomap.vh` со строками вида `localparam IO_LED_BIT = 10;`, и `csr.json` с объектом `{"bus":"j1-io","devices":[…]}`, где у каждого устройства есть `name`, `bit`, `addr`, `width`, `access`. Числа во всех трёх файлах MUST совпадать для каждого устройства.

#### Scenario: Согласованные экспорты
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build`
- **THEN** `csr.fs` содержит `$400 constant IO-LED` и `$800 constant IO-TIMER`, `iomap.vh` содержит `IO_LED_BIT = 10` и `IO_TIMER_BIT = 11`, `csr.json` содержит устройство `led` с `"addr":1024` и `"bit":10`, и тест сравнения трёх файлов проходит

### Requirement: Обёртка декодирует по карте
`cpu/j1/j1_wrap.v` MUST включать `iomap.vh` и MUST выбирать устройство по `mem_addr[IO_<ИМЯ>_BIT]`. Литералы битов адреса (`mem_addr[10]` … `mem_addr[13]`) MUST NOT стоять в обёртке. Стенд Icarus MUST записывать по адресам из `iomap.vh` и читать обратно.

#### Scenario: Стенд обёртки
- **WHEN** запущен `rtl/tb_j1_wrap_io.v`
- **THEN** запись 1 по адресу `1 << IO_LED_BIT` поднимает `led`, запись 30 по `1 << IO_TIMER_BIT` даёт убывающее чтение, и `rg "mem_addr\[1[0-3]\]" cpu/j1/j1_wrap.v` пусто

### Requirement: Старая карта CSR удалена
Слова `cores-minimal-soc`, `cores-uart`, `cores-gpio`, `cores-timer`, `cores-ctrl` и файл `fsoc/soc/cores.4th` MUST NOT существовать. Файл `csr.4th` MUST NOT записываться в каталог проекта.

#### Scenario: Нет фиктивной карты
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** в каталоге нет `csr.4th`, есть `csr.fs`, `iomap.vh`, `csr.json`, и `rg "cores-|CSR-uart-rxtx" fsoc/ tests/` пусто
