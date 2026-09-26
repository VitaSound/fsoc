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
Файл `designs/soc_top.4th` MUST описать вход `uart_rx` и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий аргументом генератора `--out`; дизайн MUST NOT читать переменные окружения. Провод приёма MUST входить в ядро. Привязка приёма к константе 1 в обёртке MUST NOT оставаться единственным входом.

#### Scenario: Топ не знает каталог эмуляции
- **WHEN** читается `designs/soc_top.4th`
- **THEN** в файле есть `uart_rx`, нет `projects/`, нет `soc_emul` и нет `getenv`, а `top.v` проекта `soc_emul` имеет вход `uart_rx`

#### Scenario: Плата без serial
- **WHEN** в `projects/soc_blink_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_SYNTH_SKIP=1`
- **THEN** `top.v` не содержит `input wire uart_rx`, а приём ядра привязан к `1'b1`

### Requirement: Запуск сеанса
Без заданной строки ввода `fsoc --build` MUST запустить Verilator до Ctrl+C или до `FSOC_EMU_CYCLES` и MUST читать следующие строки с stdin или с панели. Со строкой ввода из `FSOC_EMU_UART_IN` и с `FSOC_EMU_FAST=1` прогон MUST завершиться с кодом 0 после последнего ответа ` ok` и с кодом 1, если ответ не пришёл до предела. Просмотр MUST NOT завершаться по содержимому байтов UART или по числу переключений пина. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Скриптованная строка заканчивает тест
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** код возврата 0, а журнал содержит байт `3` и ответ ` ok`

#### Scenario: Blink завершается по пределу
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build` с `FSOC_EMU_FAST=1`, `FSOC_EMU_CON=term` и `FSOC_EMU_CYCLES=200000`
- **THEN** код возврата 0, вывод содержит `lamp on` и `lamp off` и не содержит ` ok`

### Requirement: Отчёт сборки называет генератор top.v
Успешный `fsoc --build` в проекте SoC MUST напечатать `fhdlgen: <имя>` для выходного файла топа и для каждого включённого листа — строками, которые печатает сам генератор из своего фрагмента, а не литералами билдера. Секция `Software` MUST напечатать путь исходника ядра и путь каждого подаваемого файла прошивки из того же значения, что подставлено в команду, затем `firmware.hex: <байт> bytes of 8192`, и MUST напечатать, сколько байт из 8192 занял словарь ядра и чему равен указатель кода. Предупреждения Gforth MUST остаться на экране. Строка `tdp` MUST NOT склеиваться с текстом предупреждения.

#### Scenario: Две строки вместо emit ok и tdp
- **WHEN** сборка ядра проходит успешно
- **THEN** в выводе есть `fhdlgen: top.v` и строка `SwapForth nucleus: dictionary at $` с байтами из 8192 и указателем кода, а в `fsoc/tasks/soc.4th` нет литерала `fhdlgen: top.v`

#### Scenario: Имена из генератора и из команды
- **WHEN** в `projects/soc_blink` сборка проходит успешно
- **THEN** в выводе есть `fhdlgen: top.v`, `fhdlgen: timer.v`, `fhdlgen: regio.v`, строка с `swapforth/j1a/nuc.fs`, строка с `swapforth/j1a/swapforth.fs`, строка с `firmware/lamp.fs`, строка `SwapForth nucleus: dictionary at $` и строка `firmware.hex:` с числом байт, а в `fsoc/tasks/soc.4th` нет литералов `fhdlgen: top.v`, `cross:` и `firmware:`

### Requirement: Кросс-компилятор совместим с Gforth 0.7
Двойной ноль MUST записываться как `#0.`, чтение 16-битной ячейки MUST использовать `w@`, поле N ядра MUST называться `nos`, чтобы не заменять слово `n` из Gforth. Предупреждение `redefined noop` MUST оставаться: словарное `noop` намеренно занимает имя макроса ассемблера и делит выход с `execute`.

#### Scenario: Сборка ядра без лишних предупреждений
- **WHEN** Gforth собирает `cross.fs`, `basewords.fs` и `nuc.fs`
- **THEN** нет предупреждений про `0.`, `uw@` и переопределение `n`, и есть предупреждение `redefined noop`

### Requirement: Дизайн не знает способ запуска
Файл в `designs/` MUST описывать модуль SoC и MUST NOT называть каталог проекта, плату или способ запуска. Путь выходного Verilog MUST задавать вызывающий аргументом генератора `--out`; дизайн MUST NOT читать переменные окружения. Слой MUST NOT подставлять свой каталог, если путь не передан.

#### Scenario: Топ без каталога эмуляции
- **WHEN** читается `designs/soc_top.4th`
- **THEN** в файле нет `projects/`, нет `soc_emul` и нет `getenv`, а `top.v` пишется только в каталог из `--out`

### Requirement: main SoC не лежит в emu
`emu/` MUST содержать только общую библиотеку эмуляции и MUST NOT содержать `main` задачи SoC. `main` MUST жить рядом с задачей в `fsoc/tasks/` и MUST соединять порты `Vtop` со словами библиотеки, не повторяя цикл тактов и UART-кодек. Сборка эмуляции MUST копировать его в каталог проекта вместе с библиотекой.

#### Scenario: main рядом с задачей
- **WHEN** собрана эмуляция SoC
- **THEN** `main` взят из `fsoc/tasks/soc_main.cpp`, в каталоге проекта есть его копия и копии `emu/*.cc`, а в `emu/` нет файла с именем soc

### Requirement: Запуск как у blinky
Идентичность проекта MUST читаться из `target.4th`: задача `soc`, таргет `emulation`, плата не задана. `fsoc --build` MUST породить `top.v`, `firmware.hex`, `csr.fs`, `iomap.vh`, `csr.json` и `sim.sh`, затем запустить просмотр. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Сборка из каталога проекта
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** появляются `top.v`, `firmware.hex`, `sim.sh`, `csr.fs`, `iomap.vh` и `csr.json`, Verilator компилируется и просмотр идёт до Ctrl+C

### Requirement: Образ прошивки собирает отдельный шаг
`firmware.hex` MUST создавать шаг `feed`, отделённый от интерактивного просмотра: билдер MUST подготовить плоский файл подачи (раскрыв `include` SwapForth), запустить `feed` и получить `firmware.hex` из обёртки. Переменная `FSOC_EMU_SNAPSHOT` MUST NOT использоваться. Интерактивный просмотр MUST только загрузить готовый `firmware.hex`.

#### Scenario: Сборка образа без интерактивного main
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build`
- **THEN** в каталоге появляются плоский файл подачи, `obj_dir/Vtop_feed` и `firmware.hex` на 4096 строк, а `rg FSOC_EMU_SNAPSHOT fsoc/ emu/ targets/` пусто

### Requirement: Прошивка берёт адреса из карты
Файл прошивки проекта (`firmware/lamp.fs` и последующие) MUST начинаться с `include csr.fs` и MUST обращаться к шине через константы `IO-<ИМЯ>`. Литералы адресов `h# 400`, `h# 800`, `h# 1000`, `h# 2000` MUST NOT стоять в прошивке проекта. Билдер MUST подать `csr.fs` в образ до прошивки проекта.

#### Scenario: Лампа через константы
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build` с `FSOC_EMU_FAST=1`, `FSOC_EMU_CON=term`, `FSOC_EMU_CYCLES=200000`
- **THEN** вывод содержит `lamp on` и `lamp off`, `firmware/lamp.fs` содержит `IO-LED` и `IO-TIMER`, а `rg "h# *(400|800|1000|2000)" firmware/` пусто

### Requirement: SoC собирается на плате
В проекте с `s" soc" task:`, `s" quartus" target:` и платой, у которой описаны ресурсы `clk50`, `user_led` и `serial` с `tx` / `rx`, `fsoc --build` MUST записать `top.v`, листы, `soc.qsf`, `soc.sdc`, `build.sh`, `load.sh` и `firmware.hex` в каталог проекта и MUST NOT запускать Quartus. `.qsf` MUST содержать `DEVICE` и `FAMILY` платы и назначения пинов `clk`, `led`, `uart_tx`, `uart_rx` из ресурсов платы. Порты `rst` и `dump` MUST быть привязаны к 0 внутри топа платы и MUST NOT требовать пинов. `--load` MUST выполнить `load.sh`.

#### Scenario: VitaSound EP4CE10
- **WHEN** в `projects/soc_vitasound_ep4ce10` выполняется `fsoc --build`
- **THEN** `soc.qsf` содержит `DEVICE EP4CE10E22C8`, `FAMILY Cyclone IV E`, `PIN_23 -to clk`, `PIN_86 -to led`, `PIN_114 -to uart_tx`, `PIN_115 -to uart_rx`, `top.v` не имеет входов `rst` и `dump` в списке портов, `firmware.hex` содержит 4096 строк, а Quartus не запускался

### Requirement: Делитель UART из частоты такта
Обёртка J1 MUST получать `CLK_HZ` и `BAUD` параметрами инстанса. Значение `CLK_HZ` MUST приходить от тактового ресурса, который запросила задача: у платы — из её описания, у эмуляции — из таргета. Эмуляция MUST вести UART тем же делителем, что стоит в `top.v`. Литерал делителя MUST NOT стоять ни в обёртке, ни в `main`, ни в тесте.

#### Scenario: Одна частота, два таргета
- **WHEN** собраны `projects/soc_emul` и `projects/soc_vitasound_ep4ce10`
- **THEN** оба `top.v` содержат `CLK_HZ(50000000)` и `BAUD(115200)`, `sim.sh` эмуляции передаёт делитель, вычисленный из этих чисел, и сеанс `1 2 + .` в эмуляции отвечает `3` и ` ok`

### Requirement: fterm говорит с портом
`fterm` MUST принимать путь устройства аргументом, настроить его на 115200 8N1 без эха, отправить строку с LF и читать ответ до ` ok` или до предела попыток. Без аргумента `fterm` MUST использовать тестовый backend с ответом из памяти. Ответ `?` MUST печататься как ошибка строки, а сеанс MUST продолжаться.

#### Scenario: Тестовый backend
- **WHEN** `fterm-line` вызван с `1 2 +` без устройства
- **THEN** возвращает истину и печатает `ok`

#### Scenario: Реальный порт
- **WHEN** плата прошита образом `soc_console` и выполнен `gforth tools/fterm.4th /dev/ttyUSB0` со строкой `1 2 + .`
- **THEN** на экране появляется `3  ok`; проверка ручная, вне `fmix test`

### Requirement: Лампа на Colorlight
Проект `projects/soc_blink_colorlight_5a_75e_v6_0` MUST собираться задачей `soc`, таргетом `yosys` и платой `colorlight_5a_75e_v6_0` с опцией `s" lamp" s" 1" option:`. Тактом MUST быть `plat-clock` этой платы (25 МГц). Топ платы MUST получить `CLK_HZ` этой частоты, `BOARD=1`, `NO_UART=1`, `LED_LOW=1` и `TIMER_DIV`, равный `CLK_HZ/1000`. Порты `uart_rx`, `uart_tx`, `rst` и `dump` MUST NOT входить в список портов этого топа: приём привязан к `1'b1`, сброс и `dump` — к `1'b0`, выход `led` инвертирован. Образ `firmware.hex` MUST получаться прогоном feed на 50 МГц, после чего топ платы записывается заново с частотой платы. Период лампы в `firmware/lamp.fs` MUST быть 500. Yosys MUST читать Verilog с `-DSYNTHESIS`, а `$writememh` в обёртке MUST быть внутри `ifndef SYNTHESIS`.

#### Scenario: Файлы без синтеза
- **WHEN** в `projects/soc_blink_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_SYNTH_SKIP=1`
- **THEN** `soc.lpf` содержит `SITE "P6"`, `SITE "T6"` и `FREQUENCY PORT "clk" 25.000 MHz`, `top.v` содержит `CLK_HZ(25000000)`, `TIMER_DIV(25000)` и `assign led = ~led_q`, в `top.v` нет `input wire uart_rx`, `output wire uart_tx` и `input wire rst`, нет `sim.sh`, а `firmware.hex` содержит 4096 строк
