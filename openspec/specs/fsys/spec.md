# fsys Specification

## Purpose

Второй инструмент образа рядом со SwapForth: ассемблер fasm, ядро kernel и общий словарь common на том же чипе и UART.

## Requirements

### Requirement: Голый ассемблер пишет команды без Форта
Слой fasm MUST определять каждую однокомандную операцию своего процессора словом с запятой на конце. Между `[asm]` и `[endasm]` MUST лежать только команды и метки. В этом образе MUST NOT быть словаря, `quit` и ответа ` ok`. `[endasm]` MUST напечатать строки для `$readmemh` и MUST NOT запускать подачу по UART. Слово Форта из двух команд (`@`, `!`, `io@`, `io!`) MUST NOT быть словом fasm. Куски `@,`, `!,`, `io@,` и `iord,` MUST остаться однокомандными.

Общие формы адреса MUST быть `imm,`, `jmp,`, `call,`, `0branch,`. Метка MUST запоминать адрес команды.

Только j1a MUST иметь `-,`, `2/,`, `2*,`. Только j1b MUST иметь `rshift,`, `lshift,`, `depths,`, `dup@,`. У j1b `@,` MUST быть одной командой чтения `$6C00`.

#### Scenario: Программа из примера на j1a
- **WHEN** хост собирает текст `[asm] main: 1 imm, 2 imm, add call, spin: spin jmp, add: +, exit, [endasm]` слоем `fsys/fasm/j1a`
- **THEN** строки образа — `8001`, `8002`, `4004`, `0003`, `6203`, `608c`, и в них нет имени `quit`

#### Scenario: Та же программа на j1b упакована по два
- **WHEN** тот же текст собирает слой `fsys/fasm/j1b`
- **THEN** три слова образа — `80028001`, `00034004`, `608c6203`

#### Scenario: Чтение памяти j1b — одна команда
- **WHEN** слой `fsys/fasm/j1b` исполняет `@,`
- **THEN** в буфер записано одно слово с младшими битами `6C00`

### Requirement: Kernel даёт консоль words и сложение
Слой kernel MUST быть отдельным для каждого id (`j1a`, `j1b`, `avr`) и MUST быть написан словами fasm своего процессора. Общего текста ядра на разные id MUST NOT быть. Каталог слоя MUST называться `kernel`. Имена `nuc` и `core` для этого слоя MUST NOT использоваться.

Образ после kernel MUST содержать словарь с `words`, компилятор `:`, `;`, `if`, `then`, `begin`, `again` и интерпретатор `quit`. Ответ строки MUST кончаться на ` ok`.

Ядро `avr` MUST NOT быть циклом мигания `PB0`.

#### Scenario: words и сложение на j1a
- **WHEN** манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" j1a" cpu:`, `s" fsys" sys:` и в образ входит kernel, а сеанс получает строки `words` и `1 2 + .`
- **THEN** передача содержит имена словаря, байт `3` и ответ ` ok`

#### Scenario: words и сложение на j1b
- **WHEN** манифест содержит `s" j1b" cpu:` и `s" fsys" sys:` и в образ входит kernel этого процессора, а сеанс получает `1 2 + .`
- **THEN** передача содержит байт `3` и ответ ` ok`, и hex не совпадает с образом j1a

#### Scenario: Kernel AVR — консоль
- **WHEN** хост читает `fsys/kernel/avr/kernel.4th`
- **THEN** в образе есть имя `quit` и имя `words`

#### Scenario: Сеанс AVR через avr-con
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:`, `s" avr" cpu:`, `s" fsys" sys:`, выполнен `fsoc --build` во временном каталоге, установлены `simavr` и `libsimavr-dev`, и `tools/avr-con` получает `1 2 + .`, затем отдельно `1 2 3` и `.s`
- **THEN** первая передача содержит `3` и ` ok`, вторая содержит `<3> 1 2 3` и ` ok`, нет `PC past image`, и `11 .` печатает `11` (не `267`)

### Requirement: Accept стирает символ на каждом id
`accept` kernel `j1a`, `j1b` и `avr` MUST трактовать байт 8 и байт 127 как стирание. Если в строке уже есть символы, длина MUST уменьшиться на один, байт MUST NOT попасть в TIB, и передача MUST выдать байты 8, 32, 8. Если строка пуста, байт MUST быть отброшен и длина MUST остаться 0.

#### Scenario: Стирание на j1a
- **WHEN** манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" j1a" cpu:`, `s" fsys" sys:`, и сеанс получает строку `12`, байт 8, затем `3 .`
- **THEN** передача содержит `13` и ` ok`, и нет результата `123`

#### Scenario: Стирание на j1b
- **WHEN** тот же сеанс на `s" j1b" cpu:` и `s" fsys" sys:`
- **THEN** передача содержит `13` и ` ok`

#### Scenario: Стирание на avr
- **WHEN** манифест содержит `s" avr" cpu:`, `s" fsys" sys:`, `s" proteus" target:`, и `avr-con` получает ту же последовательность
- **THEN** передача содержит `13` и ` ok`

### Requirement: Общий сеанс консоли fsys
Сеанс `s" fsys" sys:` на `j1a`, `j1b` и `avr` MUST отвечать одинаково на ввод строки, неизвестное слово, помещение и снятие клетки, `+`, `.s`, `: … ;` и на пересечение имён `words`. Ответ строки MUST кончаться на ` ok`. Неизвестное слово MUST напечатать `?`, после чего следующая строка MUST исполняться. SwapForth MUST NOT быть источником этого сеанса.

#### Scenario: Ядро сеанса на трёх id
- **WHEN** на каждом id поданы строки `1 2 + .`, `NOWORD`, `1 .`, `.s`, `1 2 3 .s`, `: DOUBLE DUP + ;`, `21 DOUBLE .`, `words`
- **THEN** есть `3`, `?`, `1`, `<0>`, `<3> 1 2 3`, `42`, ` ok`, и в `words` есть каждое имя пересечения трёх словарей fsys

### Requirement: Words совпадает с JSON образа
Вывод `words` MUST содержать каждое видимое имя эталона `doc/j1-word-graph/fsys-j1a.json`, `fsys-j1b.json` или `fsys-avr-extra-min.json` для того id. Пропавшее имя MUST провалить проверку. Публичные и compile-only слова MUST иметь поведенческую строку; внутренности компилятора MAY быть только в `words`.

#### Scenario: Полный словарь j1a
- **WHEN** сеанс fsys j1a получает `words`
- **THEN** каждое имя `fsys-j1a.json` есть в передаче

#### Scenario: Полный словарь extra-min AVR
- **WHEN** сеанс extra-min AVR получает `words`
- **THEN** каждое имя `fsys-avr-extra-min.json` есть в передаче

### Requirement: Консольные тесты fsys сопровождают каждый id
`tests/con_core_test.4th` MUST гонять один сеанс `s" fsys" sys:` на каждом id с консольным kernel (`j1a`, `j1b`, `avr` и любой следующий). Прогон MUST входить в `fmix test`. Новый id с `fsys` MUST: добавить манифест в `tests/con_session.4th`; включить его в `tests/con_core_test.4th`; завести эталон `doc/j1-word-graph/fsys-<id>*.json` через `doc/j1-word-graph/build.py`; пометить каждое имя в `tests/con_words.py` (`run` / `colon` / `skip` с причиной); обработать BS/DEL в `accept` этого kernel той же семантикой. Слова, уникальные для id, MUST жить в отдельном тесте (как `tests/avr_con_test.4th`) и MUST NOT дублировать общее ядро. SwapForth MUST NOT быть источником этого сеанса.

Точечный прогон: из `tests/` при заданном `FSOC_HOME` — `gforth con_core_test.4th`. AVR без `simavr` / `libsimavr-dev` MUST пропускать свой кусок и MUST NOT валить набор.

#### Scenario: Новый fsys-id в сетке
- **WHEN** в `fsoc/cpu.4th` появляется id с консольным kernel и `s" fsys" sys:`
- **THEN** `con_core_test` гоняет этот id, JSON словаря существует, и `con_words.py tags` не оставляет безымянных ключей

### Requirement: Common один на оба процессора
Слой common MUST быть одним текстом для j1a и j1b. Его MUST компилировать **хост** (Gforth на машине сборки) в образ kernel; **цель** (j1a или j1b) MUST только исполнять готовый `firmware.hex`. Запущенный kernel на цели MUST NOT компилировать common при сборке. Каталог MUST называться `common`. Каталог `upper` MUST NOT создаваться. В тексте MUST NOT быть константы ширины клетки в байтах.

Сверх kernel образ MUST содержать `variable`, `constant`, `create`, `.`, `."`, `type`, `/`, `mod`, `/mod`, `else`, `while`, `repeat`. Полный список ANS CORE спецификации `soc` для этого образа MUST NOT требоваться.

#### Scenario: Переменная и деление на обоих процессорах
- **WHEN** один и тот же файл common загружен в образ j1a и в образ j1b с `s" fsys" sys:` хостовым компилятором, и сеанс на цели получает `variable x  5 x !  x @ .`, затем `10 3 / .`
- **THEN** первая строка печатает `5`, вторая печатает `3`, и оба ответа кончаются на ` ok`

### Requirement: Хост пишет словарь, цель его исполняет
Сборка `s" fsys" sys:` MUST собирать kernel словами fasm на хосте, затем MUST прочитать `fsys/common` (и для j1b — `fsys/j1b/extra.4th`, для j1a при `s" extra-min" s" 1" option:` — `fsys/j1a/extra-min.4th`, для `avr` без `blink` — `fsys/avr/extra-min.4th`, для `avr` с `blink=1` — `fsys/avr/extra.4th`, при `lamp=1` — `firmware/lamp.fs`, при `blink=1` — `firmware/blink.fs`) хостовым компилятором и MUST записать `firmware.hex` без `Vtop_feed` на этом пути. Цель MUST оставить консольный компилятор `:` для строк UART. `extra-min` на j1a MUST NOT грузиться по умолчанию: после него остаётся мало места под TIB для интерактивной компиляции. На `avr` консоль MUST грузить `extra-min` по умолчанию.

#### Scenario: Размер образа без подачи симулятора
- **WHEN** манифест содержит `s" fsys" sys:` и `s" j1a" cpu:`, и выполнен `fsoc --build`
- **THEN** `firmware.hex` уже лежит в каталоге проекта до старта эмуляции, а в журнале есть строки `fsys/common/common.4th` и `fsys/common/core.4th`

#### Scenario: extra-min на консоли j1a
- **WHEN** манифест содержит `s" fsys" sys:`, `s" j1a" cpu:` и `s" extra-min" s" 1" option:`, и выполнен `fsoc --build`
- **THEN** в журнале есть `fsys/j1a/extra-min.4th`, и `here` строго меньше 8066

#### Scenario: extra-min на консоли AVR
- **WHEN** манифест содержит `s" fsys" sys:`, `s" avr" cpu:`, `s" proteus" target:` без опции `blink`, и выполнен `fsoc --build`
- **THEN** в журнале есть `fsys/avr/extra-min.4th`, нет `fsys/avr/extra.4th`, и `firmware.hex` оканчивается на `:00000001FF`

#### Scenario: extra AVR в журнале blink release
- **WHEN** манифест содержит `s" fsys" sys:`, `s" avr" cpu:`, `s" proteus" target:`, `s" blink" s" 1" option:`, `s" image" s" release" option:` и выполнен `fsoc --build`
- **THEN** в журнале есть `fsys/avr/extra.4th`, `fsys/avr/release.4th` и `firmware/blink.fs`, нет `fsys/avr/extra-min.4th`, и `firmware.hex` оканчивается на `:00000001FF`

### Requirement: Лампа не дописывается в голый образ
`firmware/lamp.fs` MUST оставаться вне fsys. Билдер MUST дописать его только если инструмент оставил Форт, который может этот файл загрузить. В образ из одного `[asm]` лампа MUST NOT дописываться.

#### Scenario: Голый asm и опция лампы
- **WHEN** манифест содержит `s" fsys" sys:` и `s" lamp" s" 1" option:`, а инструмент записал только `[asm]`
- **THEN** `firmware.hex` не содержит текст лампы, и в журнале нет `lamp on`

### Requirement: Приложение blink вне fsys
`firmware/blink.fs` MUST оставаться вне fsys. Билдер MUST дописать его только при `s" blink" s" 1" option:` и только если инструмент оставил Форт, который может этот файл загрузить.

#### Scenario: Консоль без blink
- **WHEN** манифест AVR с `s" fsys" sys:` без опции `blink`
- **THEN** в `firmware.hex` нет последовательности байт текста `blink on`

### Requirement: Покрытие слоя не ниже 90 процентов
Каждый слой fsys MUST быть закрыт тестами так, что отчёт `fcov` по его файлам не ниже 90%. Порог MUST считаться отдельно для `fsys/fasm/j1a`, `fsys/fasm/j1b`, `fsys/fasm/avr`, `fsys/kernel/j1a`, `fsys/kernel/j1b`, `fsys/kernel/avr`, `fsys/common` и `fsys/avr`. Каждый новый каталог fasm, kernel и extra MUST входить в этот порог отдельно. Среднее по слоям MUST NOT засчитываться. Сверка hex и строки `1 2 + .` MUST NOT заменять этот порог. Монолит SwapForth этим порогом MUST NOT измеряться.

#### Scenario: Отчёт по каждому слою
- **WHEN** после тестов слоя выполнен `fcov` по его каталогу
- **THEN** доля покрытия этого каталога не меньше 90, и провал одного каталога не закрывается высоким процентом другого

### Requirement: Новый id повторяет слои fsys
Новый id с `s" fsys" sys:` MUST получить те же слои, что `j1a` / `j1b` / `avr`, каждый в своём каталоге: `fsys/fasm/<id>/` (только запятые-команды), `fsys/kernel/<id>/kernel.4th`, `fsys/host/<id>-cross.4th`, `fsys/<id>/extra.4th` и `release.4th`. Кросс J1 (`fsys/host/cross.4th`) MUST NOT собирать колоны MCU.

#### Scenario: Слои AVR на диске
- **WHEN** профиль `avr` собирает `s" fsys" sys:`
- **THEN** на диске есть `fsys/fasm/avr/`, `fsys/kernel/avr/kernel.4th`, `fsys/host/avr-cross.4th`, `fsys/avr/extra.4th`, и `firmware/blink.fs` не находится под `fsys/fasm/`

### Requirement: Common не копируют на каждый id
`fsys/common` MUST оставаться одним текстом, если новый кросс его читает. Иначе кросс MUST дать те же имена (`if` `then` `variable` …) и MUST NOT копировать `common.4th` в каталог id. Класс 0 (J1) MUST держать Verilog-комплект под `cpu/j1/<id>/`. Класс 1 (MCU на кремнии) MUST NOT требовать HDL ядра процессора в этом репозитории.

#### Scenario: AVR не копирует common
- **WHEN** читается дерево `fsys/avr/`
- **THEN** в нём нет файла `common.4th`

### Requirement: Ядро нового id — консоль
Ядро MUST быть консолью Форта: стеки, `@` `!`, UART `KEY`/`EMIT`, `:`, `;`, `quit`, `words`, ответ ` ok`. Ядро MUST NOT быть циклом ввода-вывода приложения. Приложение (`'BOOT`, мигание, текст лампы) MUST лежать в `firmware/<name>.fs` и MUST дописываться опцией манифеста. Исходник приложения MUST NOT лежать в `fsys/fasm/<id>/`.

#### Scenario: Ядро не есть blink
- **WHEN** читается `fsys/kernel/avr/kernel.4th`
- **THEN** в тексте есть `quit` и `words`, и ядро не описывается как цикл `sbi` на `DDRB`/`PORTB` без интерпретатора

### Requirement: Blinky на AVR пишет HEX без Forth
Задача `blinky` с `cpu:` AVR MUST собрать текст `[asm]` из `firmware/blink_avr.4th` словами fasm, MUST записать `firmware.hex` и MUST NOT включать kernel, `quit` и `s" fsys" sys:`. Каталог рабочего проекта MUST быть `projects/baremetal/blinky_atmega`. Имя задачи MUST быть `blinky`; fasm MUST остаться инструментом в журнале (`image tool: fasm`).

#### Scenario: Голый AVR без quit
- **WHEN** манифест содержит `s" blinky" task:`, `s" proteus" target:`, `s" avr" cpu:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` оканчивается на `:00000001FF`, в журнале есть `image tool: fasm` и нет имени `quit` в образе

### Requirement: Ядро не есть файл blink_avr
`firmware/blink_avr.4th` MUST NOT лежать в `fsys/kernel/` и MUST NOT лежать в `fsys/fasm/`.

#### Scenario: Мигалка вне kernel
- **WHEN** читается дерево `fsys/kernel/avr/`
- **THEN** в нём нет `blink.4th`

### Requirement: Следующая приёмка — плата и Proteus
Автотесты (`fmix test`, Verilator, `avr-con`) MUST подтверждать сборку и консоль. Следующая приёмка после автотестов MUST идти на железных FPGA-платах из `boards/` (Colorlight 5A-75E, Terasic DE0-Nano и последующие) и в Proteus для профиля `avr`. Успех Verilator или `avr-con` MUST NOT считаться заменой прогона на живой плате или в Proteus.

#### Scenario: AVR blink в Proteus
- **WHEN** собран `projects/soc_atmega8_blink` и HEX открыт в Proteus (ATMEGA8, 8 МГц, Virtual Terminal 9600)
- **THEN** терминал MUST показать строки `blink on` и `blink off`

#### Scenario: FPGA на железе
- **WHEN** пользователь шьёт проект с `target:` `quartus` или `yosys` на плату из `boards/`
- **THEN** приёмка MUST включать наблюдение UART и/или светодиода на кристалле, не только лог эмуляции
