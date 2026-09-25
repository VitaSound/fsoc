# soc Specification

## Purpose

Задача SoC исполняет SwapForth J1a: образ с её полным словарём отвечает на строку так же, как эта система на своём UART.

## Requirements

### Requirement: Образ собирает кросс-компилятор SwapForth
Прошивка MUST быть образом SwapForth J1a, собранным Forth-кросс-компилятором из исходников, а не готовым hex и не текстом `j1_prompt`. Сборка MUST загрузить этот образ в память J1. Ядро MUST исполнить его. Байты консоли MUST появиться из этого исполнения. Модуль `j1_prompt` MUST NOT быть их источником.

#### Scenario: Hex совпадает со сборкой SwapForth
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** `firmware.hex` совпадает с выходом сборки SwapForth, исходники прошивки остаются Forth-текстом, а в `top.v` нет `j1_prompt`

### Requirement: Словарь SwapForth J1a
Словарь загруженного образа MUST содержать каждое слово ANS CORE, кроме `environment?`. Слова `environment?` в образе MUST NOT требоваться. MUST также быть найдены слова, которые добавляет интерактивный образ J1a: `io@` `io!` `key?` `words` `.s` `.x` `.x2` `nip` `tuck` `-rot` `false` `true` `u>` `within` `erase` `.(` `hex` `marker` `pad` `unused` `see` `dump` `ms` `leds` `new` `.xt` `case` `of` `endof` `endcase` `save-input` `restore-input` `convert` `[compile]`.

ANS CORE, который MUST присутствовать: `!` `#` `#>` `#s` `'` `(` `*` `*/` `*/mod` `+` `+!` `+loop` `,` `-` `.` `."` `/` `/mod` `0<` `0=` `1+` `1-` `2!` `2*` `2/` `2@` `2drop` `2dup` `2over` `2swap` `:` `;` `<` `<#` `=` `>` `>body` `>in` `>number` `>r` `?dup` `@` `abort` `abort"` `abs` `accept` `align` `aligned` `allot` `and` `base` `begin` `bl` `c!` `c,` `c@` `cell+` `cells` `char` `char+` `chars` `constant` `count` `cr` `create` `decimal` `depth` `do` `does>` `drop` `dup` `else` `emit` `evaluate` `execute` `exit` `fill` `find` `fm/mod` `here` `hold` `i` `if` `immediate` `invert` `j` `key` `leave` `literal` `loop` `lshift` `m*` `max` `min` `mod` `move` `negate` `or` `over` `postpone` `quit` `r>` `r@` `recurse` `repeat` `rot` `rshift` `s"` `s>d` `sign` `sm/rem` `source` `space` `spaces` `state` `swap` `then` `type` `u<` `um*` `um/mod` `unloop` `until` `variable` `while` `word` `xor` `[` `[']` `[char]` `]`.

#### Scenario: words печатает словарь
- **WHEN** после рукопожатия загрузки подана строка `words`
- **THEN** в журнале передачи есть имя каждого слова из этого требования

#### Scenario: Определение с ветвлением
- **WHEN** после рукопожатия поданы строка `: P 0 if 1 else 2 then . ;` и затем строка `P`
- **THEN** в журнале после второй строки есть байт `2`, пробел и ответ ` ok`

### Requirement: Ответ ok после строки
После сброса и до первого байта приёма передача MUST выдать CR и LF. В журнале это `uart tx 0x0d` и следом `uart tx 0x0a`. Первый байт приёма ядро MUST снять и MUST NOT исполнять его как текст. Конец строки — CR или LF. Строка MUST быть отражена в передаче, затем MUST быть исполнена. Ответ MUST закончиться пробелом, байтами `o` и `k`, CR и LF. Числа MUST быть десятичными. `.` MUST напечатать вершину и пробел. Неизвестное слово MUST напечатать `?`, после чего следующая строка MUST исполняться.

#### Scenario: Сложение
- **WHEN** эмуляция получает строку `1 2 + .`
- **THEN** первый символ строки не потерян, в журнале есть отражение этой строки, затем байт `3`, и ответ заканчивается пробелом, `o`, `k`, `uart tx 0x0d` и `uart tx 0x0a`

#### Scenario: Своё слово
- **WHEN** поданы строка `: DOUBLE DUP + ;` и затем строка `21 DOUBLE .`
- **THEN** после второй строки в журнале есть байты `4` и `2`, пробел и ответ ` ok`

#### Scenario: Неизвестное слово не роняет сеанс
- **WHEN** поданы строка `NOWORD` и затем строка `1 .`
- **THEN** в журнале есть байт `?`, а после второй строки — байт `1`, пробел и ответ ` ok`

### Requirement: Приём идёт в порт UART
Файл `designs/soc_top.4th` MUST описать вход `uart_rx` и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий через `FSOC_SOC_TOP`. Провод приёма MUST входить в ядро. Привязка приёма к константе 1 в обёртке MUST NOT оставаться единственным входом.

#### Scenario: Топ не знает каталог эмуляции
- **WHEN** читается `designs/soc_top.4th`
- **THEN** в файле есть `uart_rx`, нет `projects/` и нет `soc_emul`, а собранный `top.v` имеет вход `uart_rx`

### Requirement: Запуск сеанса
Без заданной строки ввода `fsoc --build` MUST запустить Verilator до Ctrl+C и MUST читать следующие строки с stdin. Со строкой ввода из `FSOC_EMU_UART_IN` и с `FSOC_EMU_FAST=1` прогон MUST завершиться с кодом 0 после ответа ` ok`. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Скриптованная строка заканчивает тест
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** код возврата 0, а журнал содержит байт `3` и ответ ` ok`

### Requirement: Отчёт сборки называет генератор top.v
Успешный `fsoc --build` в `projects/soc_emul` MUST напечатать выходной файл фрагмента топа строкой `fhdlgen: <имя>` из пути, уже записанного в этот фрагмент, до окончания генерации, и MUST напечатать, сколько байт из 8192 занял словарь ядра и чему равен указатель кода. Предупреждения Gforth MUST остаться на экране. Строка `tdp` MUST NOT склеиваться с текстом предупреждения.

#### Scenario: Две строки вместо emit ok и tdp
- **WHEN** сборка ядра проходит успешно
- **THEN** в выводе есть `fhdlgen: top.v` и строка `SwapForth nucleus: dictionary at $` с байтами из 8192 и указателем кода, а в `fsoc/soc.4th` нет литерала `fhdlgen: top.v`

### Requirement: Кросс-компилятор совместим с Gforth 0.7
Двойной ноль MUST записываться как `#0.`, чтение 16-битной ячейки MUST использовать `w@`, поле N ядра MUST называться `nos`, чтобы не заменять слово `n` из Gforth. Предупреждение `redefined noop` MUST оставаться: словарное `noop` намеренно занимает имя макроса ассемблера и делит выход с `execute`.

#### Scenario: Сборка ядра без лишних предупреждений
- **WHEN** Gforth собирает `cross.fs`, `basewords.fs` и `nuc.fs`
- **THEN** нет предупреждений про `0.`, `uw@` и переопределение `n`, и есть предупреждение `redefined noop`

### Requirement: Дизайн не знает способ запуска
Файл в `designs/` MUST описывать модуль SoC и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий через `FSOC_SOC_TOP`. Слой MUST NOT подставлять свой каталог, если путь не передан.

#### Scenario: Топ без каталога эмуляции
- **WHEN** читается `designs/soc_top.4th`
- **THEN** в файле нет `projects/` и нет `soc_emul`, а `top.v` пишется только по пути из `FSOC_SOC_TOP`

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

### Requirement: Запуск как у blinky
Идентичность проекта MUST читаться из `target.4th`: задача `soc`, таргет `emulation`, плата не задана. `fsoc --build` MUST породить `top.v`, `firmware.hex`, `csr.4th`, `csr.json` и `sim.sh`, затем запустить просмотр. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Сборка из каталога проекта
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** появляются `top.v`, `firmware.hex`, `sim.sh`, `csr.4th` и `csr.json`, Verilator компилируется и просмотр идёт до Ctrl+C
