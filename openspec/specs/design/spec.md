# design Specification

## Purpose

Дизайн fhdlgen в `designs/` — композиция чипа: какие листы включены, какой модуль top и как соединены порты. Дизайн не знает, кто его собирает, куда пишет и как запускает.

## Requirements

### Requirement: Дизайн не читает окружение
Файл в `designs/` MUST описывать проект fhdlgen (`hdl-project`, `hdl-include-v`, `hdl-blackbox`, `hdl-module`, `hdl-instance`) и MUST NOT вызывать `getenv`. Выходной каталог MUST приходить аргументом генератора `--out <dir>`; имя файла MUST быть `<dir>/<project.top>.v`. Значение параметра инстанса MUST приходить штатным механизмом параметров fhdlgen; дизайн MUST знать только имя параметра листа.

#### Scenario: Топ без переменных билдера
- **WHEN** читается любой файл `designs/*.4th` и `designs/lib/*.4th`
- **THEN** в нём нет `getenv`, `FSOC_`, `projects/`, имён плат и каталогов проектов

#### Scenario: Сборка во временный каталог
- **WHEN** выполняется `fhdlgen build designs/blinky_top.4th --out /tmp/x`
- **THEN** появляются `/tmp/x/top.v`, `/tmp/x/top-module` со строкой `top` и `/tmp/x/includes.lst` со строкой `blinky.v`

#### Scenario: Параметр листа
- **WHEN** `blinky_top.4th` собран с параметром `LED_BIT=4` и без него
- **THEN** первый `top.v` содержит `LED_BIT(4)`, второй не содержит `LED_BIT`

### Requirement: Генератор называет свои файлы
При сборке генератор MUST напечатать на stdout `fhdlgen: <путь выходного .v>` и `fhdlgen: <имя>` для каждого `hdl-include-v` в порядке объявления, и MUST записать те же имена в `<dir>/includes.lst`, по одному на строку. Билдер MUST брать список листов из этого файла и MUST NOT разбирать `top.v`.

#### Scenario: Листы SoC в логе и в списке
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build`
- **THEN** лог содержит строки `fhdlgen: stack2.v`, `fhdlgen: j1.v`, `fhdlgen: uart.v`, `fhdlgen: timer.v`, `fhdlgen: regio.v`, `fhdlgen: j1_wrap.v`, `fhdlgen: top.v`, `includes.lst` содержит те же шесть листов, а `awk` по `top.v` в билдере отсутствует

### Requirement: Один blackbox на обёртку
Объявление blackbox `j1_wrap` (порты `clk`, `rst`, `uart_rx`, `uart_tx`, `led`) MUST жить в одном файле `designs/lib/j1_wrap.4th`. Дизайны SoC MUST включать его, а не повторять порты.

#### Scenario: Два чипа, одна обёртка
- **WHEN** читаются `designs/soc_top.4th` и `designs/soc_console.4th`
- **THEN** ни один не содержит `hdl-blackbox`, оба содержат `included` файла `designs/lib/j1_wrap.4th`, и собранные `top.v` обоих инстанцируют `j1_wrap` с портами `uart_rx`, `uart_tx`, `led`
