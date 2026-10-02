# forth-cross Specification

## Purpose

Профили Forth для сборки образа: поле манифеста `cpu:` выбирает профиль, а излучатель берётся из его кода CG, не из имени тулчейна платы.

## Requirements

### Requirement: Профиль называется полем cpu
Манифест MAY содержать `s" <id>" cpu:`. Задача `soc` MUST собирать образ излучателем этого профиля. Имя тулчейна (`quartus`, `yosys`, `emulation`) MUST NOT выбирать профиль. Неизвестный id MUST останавливать сборку и MUST NOT подставлять `j1a`. Пустое поле у существующих проектов MUST означать `j1a`. Id процессора MUST выбирать подкаталог внутри уже выбранного `sys:`, а не каталог под `cpu/j1/`.

#### Scenario: Неизвестный профиль
- **WHEN** манифест содержит `s" no-such-cpu" cpu:` и выполняется `fsoc --build`
- **THEN** сборка останавливается с текстом, содержащим `no-such-cpu`, и каталог `swapforth/j1a` не используется

#### Scenario: Пустое поле
- **WHEN** `projects/soc_emul/target.4th` не содержит `cpu:` и выполняется сборка образа
- **THEN** кросс читает `swapforth/j1a/nuc.fs`

### Requirement: Излучатель выбирается по CG
Профиль MUST хранить класс, строку FMAP, MM, EX-C, CG и BM. Сборка образа MUST вызывать излучатель, зарегистрированный для CG этого профиля. Профили `j1a` и `j1b` MUST иметь класс 0, MM=V, EX-C=V, CG=I, BM=C. Профиль `stm8` MUST иметь класс 1 и CG=E. Профиль `z80` MUST иметь класс 2 и CG=F. Профиль `avr` MUST иметь класс 1, MM=D, EX-C=S, CG=F и BM=C. CG=E MUST NOT собирать hex. CG=F MUST писать Intel HEX только для `avr` при `s" fsys" sys:`. Для `z80` сборка MUST останавливаться до hex. Для `avr` без `fsys` сборка MUST останавливаться до hex.

#### Scenario: Каркас без образа
- **WHEN** манифест содержит `s" stm8" cpu:` или `s" z80" cpu:`
- **THEN** сборка останавливается до запуска `gforth`, и в дереве нет скопированного `forth.asm`

#### Scenario: ATmega8 пишет Intel HEX
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:`, `s" avr" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` — Intel HEX с записью `:00000001FF`, в журнале нет `gforth cross.fs`, и симулятор Proteus не запускается

#### Scenario: Текст blink
- **WHEN** к манифесту `avr` с `s" fsys" sys:` добавлено `s" blink" s" 1" option:` и `s" image" s" release" option:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` содержит байты строки `blink on`

### Requirement: J1B не затирает J1a
Исходники J1B MUST быть взяты из каталога `original/j1b` репозитория wzab/AFCK_J1B_FORTH: `cross.fs`, `basewords.fs`, `nuc.fs`, `swapforth.fs`, `verilog/j1.v`, `verilog/stack.v`, `verilog/common.h`. Файл ядра в fsoc MUST называться `j1b.v` и лежать в комплекте `cpu/j1/j1b/`. Существующий `cpu/j1/j1a/j1.v` MUST остаться с `` `define WIDTH 16 ``. VHDL, I2C и проект Vivado платы AFCK MUST NOT копироваться. Рядом MUST лежать текст лицензии BSD Боумана.

#### Scenario: Оба ядра на диске
- **WHEN** профиль `j1b` зарегистрирован
- **THEN** `cpu/j1/j1a/j1.v` содержит `WIDTH 16`, `cpu/j1/j1b/j1b.v` содержит ширину 32, а в репозитории нет `j1.vhd` из каталога `src/j1b`

### Requirement: Обёртка J1B отдельная
16-битная `j1_wrap.v` MUST NOT инстанциировать ядро ширины 32. Комплект `j1b` MUST называть файл обёртки с `WIDTH 32` и портом `mem_din`. Сборка с `cpu:` равным `j1b` MUST собирать образ этого комплекта и MUST NOT подставлять hex j1a.

#### Scenario: j1b со своим комплектом
- **WHEN** манифест содержит `s" j1b" cpu:` и выполняется сборка консоли
- **THEN** `includes.lst` содержит `j1b.v`, `stack.v`, `common.h` и `j1b_wrap.v`, `firmware.hex` содержит 8192 строки по 8 hex-цифр, и этот файл не совпадает с образом j1a

### Requirement: Инструмент образа называется полем sys
Манифест MAY содержать `s" <id>" sys:`. Пустое поле MUST означать `swapforth`. `s" swapforth" sys:` MUST собирать монолит из `swapforth/<id>/` тем же `gforth cross.fs basewords.fs nuc.fs` и MUST раскрывать `include` из `swapforth/<id>/` и `swapforth/common/`. `s" fsys" sys:` MUST собирать цепочку fsys и MUST NOT читать каталог `swapforth/` и MUST NOT подставлять hex SwapForth. Неизвестный id MUST останавливать сборку до кросса. `target:` MUST оставаться только способом запуска.

#### Scenario: Пустое sys оставляет SwapForth
- **WHEN** `target.4th` не содержит `sys:` и содержит задачу `soc`
- **THEN** сборка читает `swapforth/<id профиля>/nuc.fs`

#### Scenario: fsys не берёт файлы SwapForth
- **WHEN** манифест содержит `s" j1a" cpu:` и `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** в команде сборки образа нет `swapforth/`, и `firmware.hex` не совпадает с образом SwapForth того же `cpu:`

#### Scenario: Неизвестный инструмент
- **WHEN** манифест содержит `s" no-such-sys" sys:` и выполняется `fsoc --build`
- **THEN** сборка останавливается с текстом, содержащим `no-such-sys`, до запуска `gforth`

### Requirement: Комплект не называет прошивку
Файлы комплекта процессора MUST NOT хранить путь или имя инструмента образа. Выбор каталога прошивки MUST идти от `sys:` и id профиля.

#### Scenario: В kit нет каталога swapforth
- **WHEN** читаются `cpu/j1/j1a/kit.4th` и `cpu/j1/j1b/kit.4th`
- **THEN** в них нет строки `swapforth` и нет слова, которое подставляет путь кросса

### Requirement: Новый id процессора — семейство ISA
Новый идентификатор `cpu:` MUST означать новое семейство ISA. Профиль в `fsoc/cpu.4th` MUST задавать класс FMAP, MM, EX-C, CG и BM. Другой корпус того же ISA (`atmega328p` рядом с `atmega8`) MUST быть файлом части в `fsys/fasm/<id>/` и MUST NOT быть новым `cpu:`.

#### Scenario: Чип не есть новый cpu
- **WHEN** в репозитории есть `fsys/fasm/avr/atmega328p.4th` и `fsys/fasm/avr/atmega8.4th`
- **THEN** зарегистрированный id профиля остаётся `avr`, и отдельного `cpu:` для 328p нет

### Requirement: model: выбирает файл части
Манифест MAY содержать `s" <id>" model:`. Для `cpu: avr` сборка MUST включить `fsys/fasm/avr/<id>.4th`. Ядро MUST NOT хардкодить `atmega8.4th`. Неизвестный id MUST останавливать сборку и MUST NOT подставлять `atmega8`. Пустой `model:` MAY брать `cpu-ref` (`atmega8` у профиля `avr`). Рабочие ATmega-проекты MUST писать модель явно.

#### Scenario: Переключение части
- **WHEN** манифест содержит `s" avr" cpu:` и `s" atmega328p" model:`
- **THEN** сборка включает `fsys/fasm/avr/atmega328p.4th`, в журнале Hardware есть `atmega328p(avr)`, и `avr-flash` в словах — 16384

#### Scenario: Неизвестная модель
- **WHEN** манифест содержит `s" avr" cpu:` и `s" no-such-chip" model:`
- **THEN** сборка останавливается с текстом, содержащим `no-such-chip` или `no model`, и восьмёрка не подставляется

### Requirement: Новый fsys-id входит в консольные тесты
Новый `cpu:` с консольным kernel и `s" fsys" sys:` MUST попасть в `tests/con_core_test.4th` (манифест в `tests/con_session.4th`, эталон JSON через `doc/j1-word-graph/build.py`, теги в `tests/con_words.py`). `accept` MUST стирать байты 8 и 127 той же семантикой, что у `j1a` / `j1b` / `avr`. Другой корпус того же ISA MUST NOT требовать новый ряд `con_core`. Инструкция агента: `.cursor/rules/fsoc-cpu-target.mdc`, навык `add-cpu-target`.

#### Scenario: Платформа без ряда con_core не принята
- **WHEN** добавляют новый id с `fsys` kernel и не трогают `con_core_test`
- **THEN** требование не выполнено: сеанс, `words` и теги для этого id отсутствуют

### Requirement: Перед сдачей нового ядра — три сеанса эмуляции
Короткий `*_test.4th` (одна сумма, grep журнала сборки, `FSOC_EMU_EDGES=2`) MUST NOT быть сдачей нового `cpu:` и MUST NOT быть сдачей другого корпуса того же ISA. Последний шаг разработки, до передачи на проверку, MUST прогнать три сеанса ниже и оставить журналы. Любой провал MUST останавливать сдачу. Многоминутный прогон словаря MUST NOT называться `*_test.4th` и MUST NOT входить в `fmix`; пропуск этого файла MUST NOT считаться сдачей. Новый id с собственным kernel MUST выполнить для сеанса консоли свой ряд `con_core`, а не только записать его в файл. Другой корпус того же ISA MUST выполнить скрипт словаря порта (как `gforth tests/j1abs_words.4th`): тот же словарь, что у порта, на новом теле. Строка, которую человек набирает и завершает Enter, MUST проверяться как запуск руками: `FSOC_EMU_UART_GAP` в окружении этого прогона MUST NOT быть задана. Панель копит знаки у себя и в UART их не шлёт; по Enter строка уходит целиком (`push_line`), так же как `FSOC_EMU_UART_IN`. Медленный палец MUST NOT считаться медленным проводом. Пауза между этими байтами MUST браться из профиля, если он её задаёт, а не из переменной, которую выставил тест. Прогон, где тест сам экспортирует паузу, MUST NOT считаться этой проверкой.

#### Scenario: Голый blink мигает повторно
- **WHEN** задача `blinky` с этим `cpu:` запущена с `FSOC_EMU_CON=pin`, `FSOC_EMU_EDGES=4` и `FSOC_EMU_FAST=1`
- **THEN** в журнале строки `pin led 0` и `pin led 1` встречаются каждая не меньше двух раз

#### Scenario: Soc blink мигает
- **WHEN** задача `soc` с опцией лампы или blink этого id запущена с `FSOC_EMU_CON=pin`, `FSOC_EMU_EDGES=4` и `FSOC_EMU_FAST=1`
- **THEN** `pin led 0` и `pin led 1` встречаются каждая не меньше двух раз; если образ печатает текст, в журнале есть обе строки включения и выключения; ответ ` ok` не требуется

#### Scenario: Soc отвечает на words и выражения
- **WHEN** сеанс `s" fsys" sys:` получает `words` и не меньше двух выражений, среди них `1 2 + .` и ещё одно (определение через `:` или `.s`)
- **THEN** в передаче есть имена словаря этого образа, на сложение есть `3  ok`, и второе выражение тоже кончается на ` ok`

#### Scenario: Ручной ввод без переменной паузы
- **WHEN** сеанс консоли запускают как `fsoc --build` без `FSOC_EMU_UART_GAP` и подают `1 2 + .` одной строкой, как Enter на панели
- **THEN** журнал содержит `3  ok`; если ядру нужна пауза между байтами, её подставил профиль, а не окружение теста

#### Scenario: Одна сумма не есть сдача
- **WHEN** прошёл только `1 2 + .`, а `pin led` при `FSOC_EMU_EDGES=2` показал уровни один раз
- **THEN** ядро на проверку не сдаётся: нет повторного мигания и нет ответа `words`

### Requirement: Сборка MCU ветвится по CG
Задача `soc` MUST выбирать излучатель по полю CG профиля. `fsoc/tasks/soc.4th` MUST NOT ветвить сборку по литералу id MCU (`avr`, `stm8`, `z80` и любому следующему). Ветвление по CG MUST жить в уже зарегистрированном излучателе (`cg-f.4th` для CG=F, путь CG=I для J1). Новый CG=F с `fsys` MUST писать Intel HEX тем же излучателем CG=F.

#### Scenario: soc.4th не знает MCU-профили
- **WHEN** читается `fsoc/tasks/soc.4th`
- **THEN** в нём нет литерала `avr` и нет литерала `stm8` как ветвления сборки образа

### Requirement: MCU без SwapForth требует fsys
Пустое `sys:` MUST оставаться `swapforth`. Профиль без дерева SwapForth MUST требовать `s" fsys" sys:` и MUST останавливать сборку при пустом `sys:`. CG=E MUST NOT писать hex, пока профиль не сменит CG.

#### Scenario: AVR без fsys останавливается
- **WHEN** манифест содержит `s" avr" cpu:` без `sys:` и выполняется `fsoc --build`
- **THEN** сборка останавливается до записи hex

### Requirement: AVR печатает Hardware и Software
Сборка образа AVR MUST напечатать `Start build`, `Hardware`, строку `<model>(avr)`, `Hardware complete`, `Software`, `image tool: fsys` или `image tool: fasm`, пути собранных исходников, `firmware.hex: <байт> bytes of <ёмкость flash>`, `Software complete`. Ёмкость MUST быть `avr-flash` в байтах (у ATmega8 — 8192). Строка `ATmega8 Intel HEX` MUST NOT печататься.

#### Scenario: Консоль AVR называет чип и размер
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:`, `s" avr" cpu:`, `s" atmega8" model:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** в журнале есть `atmega8(avr)`, `image tool: fsys` и `bytes of 8192`

### Requirement: Приёмка после кросса — Proteus и живая плата
Образ AVR MUST быть пригоден для Proteus (Intel HEX, таргет `proteus` не запускает симулятор). Образ J1 MUST быть пригоден для прошивки FPGA-плат из `boards/`. Автотест кросса MUST NOT заменять эту приёмку.

#### Scenario: HEX для Proteus
- **WHEN** собран `s" avr" cpu:` с `s" fsys" sys:` и `s" proteus" target:`
- **THEN** в каталоге есть `firmware.hex`, и журнал предлагает открыть его в Proteus

#### Scenario: Дальше — плита
- **WHEN** профиль `j1a` или `j1b` собран под `quartus` или `yosys` с `board:`
- **THEN** следующий шаг приёмки MUST быть прогон на железной плате, не только Verilator
