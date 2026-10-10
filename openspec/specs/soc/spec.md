# soc Specification

## Purpose

Задача SoC исполняет fsys-консоль J1: образ отвечает на строку на UART так же, как сеанс `con_core` для этого профиля.

## Requirements

### Requirement: Образ собирает fsys
Прошивка MUST быть образом `s" fsys" sys:`, собранным из `fsys/kernel/<порт>` и слоёв host/common/extra, а не готовым hex и не текстом `j1_prompt`. Сборка MUST загрузить этот образ в память J1. Ядро MUST исполнить его. Байты консоли MUST появиться из этого исполнения. Модуль `j1_prompt` MUST NOT быть их источником. Пустое `sys:` MUST останавливать сборку.

#### Scenario: soc_emul на fsys
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** в журнале есть `image tool: fsys` и `fsys/kernel/j1a/kernel.4th`, а в `top.v` нет `j1_prompt`

#### Scenario: Пустое sys останавливается
- **WHEN** временный манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" j1a" cpu:` и не содержит `sys:`
- **THEN** сборка останавливается с текстом `needs fsys`

### Requirement: Словарь консоли fsys
Словарь загруженного образа MUST соответствовать спецификации `fsys` и эталону `doc/j1-word-graph/fsys-<id>*.json`. Сеанс MUST отвечать на `words`, `: … ;` и арифметику так же, как ряд `con_core` для этого id.

#### Scenario: words печатает словарь
- **WHEN** после рукопожатия загрузки образа fsys подана строка `words`
- **THEN** в журнале передачи есть имена из эталона словаря этого профиля

#### Scenario: Определение с ветвлением
- **WHEN** после рукопожатия образа fsys поданы строка `: P 0 if 1 else 2 then . ;` и затем строка `P`
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
Без заданной строки ввода `fsoc --build` MUST запустить Verilator до Ctrl+C или до `FSOC_EMU_CYCLES` и MUST читать следующие строки с stdin или с панели. Панель MUST копить знаки до Enter и MUST отдавать строку одним `push_line`, тем же, что `FSOC_EMU_UART_IN`. Запуск руками MUST NOT задавать `FSOC_EMU_UART_GAP`. Со строкой ввода из `FSOC_EMU_UART_IN` и с `FSOC_EMU_FAST=1` прогон MUST завершиться с кодом 0 после последнего ответа ` ok` и с кодом 1, если ответ не пришёл до предела. Проверка этой строки при снятой переменной паузы MUST давать тот же ` ok`: иначе скрипт с экспортированной паузой зелёный, а набор на панели нет. Просмотр MUST NOT завершаться по содержимому байтов UART или по числу переключений пина. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Скриптованная строка заканчивает тест
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** код возврата 0, а журнал содержит байт `3` и ответ ` ok`

#### Scenario: Та же строка без паузы из теста
- **WHEN** `fsoc --build` запущен без `FSOC_EMU_UART_GAP`, а `FSOC_EMU_UART_IN` равен `1 2 + .`
- **THEN** журнал содержит `3` и ` ok`: пауза, если она нужна ядру, пришла из профиля, как при Enter на панели

#### Scenario: Blink завершается по пределу
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build` с `FSOC_EMU_FAST=1`, `FSOC_EMU_CON=term` и `FSOC_EMU_CYCLES=200000`
- **THEN** код возврата 0, вывод содержит `lamp on` и `lamp off` и не содержит ` ok`

### Requirement: Отчёт сборки называет генератор top.v
Успешный `fsoc --build` в проекте SoC MUST напечатать `fhdlgen: <имя>` для выходного файла топа и для каждого включённого листа — строками, которые печатает сам генератор из своего фрагмента, а не литералами билдера. Секция `Software` MUST напечатать `image tool: fsys`, путь kernel и путь каждого подаваемого файла прошивки, затем `firmware.hex: <байт> bytes of <ёмкость>`. Предупреждения Gforth MUST остаться на экране.

#### Scenario: Имена из генератора и из fsys
- **WHEN** в `projects/soc_blink` сборка проходит успешно
- **THEN** в выводе есть `fhdlgen: top.v`, `fhdlgen: timer.v`, `fhdlgen: regio.v`, `image tool: fsys`, строка с `fsys/kernel/j1a/kernel.4th`, строка с `firmware/lamp.fs` и строка `firmware.hex:` с числом байт, а в `fsoc/tasks/soc.4th` нет литералов `fhdlgen: top.v`, `cross:` и `firmware:`

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

### Requirement: Образ прошивки собирает шаг fsys
Задача `soc` MUST вызвать один шаг `s" fsys" sys:`. Hex MUST записать шаг fsys (`kernel-save` / эквивалент профиля). Переменная `FSOC_EMU_SNAPSHOT` MUST NOT использоваться. Интерактивный просмотр MUST только загрузить готовый `firmware.hex`.

#### Scenario: Сборка образа fsys
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build`
- **THEN** в каталоге появляется `firmware.hex` на 4096 строк (j1a), в журнале есть `image tool: fsys`, а `rg FSOC_EMU_SNAPSHOT fsoc/ emu/ targets/` пусто

#### Scenario: Задача не содержит swapforth
- **WHEN** читается `fsoc/tasks/soc.4th`
- **THEN** в нём нет строки `swapforth`

### Requirement: Прошивка берёт адреса из карты
Файл прошивки проекта (`firmware/lamp.fs` и последующие) MUST начинаться с `include csr.fs` и MUST обращаться к шине через константы `IO-<ИМЯ>`. Литералы адресов `h# 400`, `h# 800`, `h# 1000`, `h# 2000` MUST NOT стоять в прошивке проекта. Билдер MUST подать `csr.fs` в образ до прошивки проекта.

#### Scenario: Лампа через константы
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build` с `FSOC_EMU_FAST=1`, `FSOC_EMU_CON=term`, `FSOC_EMU_CYCLES=200000`
- **THEN** вывод содержит `lamp on` и `lamp off`, `firmware/lamp.fs` содержит `IO-LED` и `IO-TIMER`, а `rg "h# *(400|800|1000|2000)" firmware/` пусто

### Requirement: SoC собирается на плате
В проекте с `s" soc" task:`, `s" quartus" target:` и платой, у которой описаны ресурсы `clk50`, `user_led` и `serial` с `tx` / `rx`, `fsoc --build` MUST записать `top.v`, листы, `soc.qpf`, `soc.qsf`, `soc.sdc`, `build.sh`, `load.sh` и `firmware.hex` в каталог проекта и MUST NOT запускать Quartus. `.qpf` MUST содержать `PROJECT_REVISION = "soc"`. `.qsf` MUST содержать `DEVICE` и `FAMILY` платы в кавычках и назначения пинов `clk`, `led`, `uart_tx`, `uart_rx` из ресурсов платы. Порты `rst` и `dump` MUST быть привязаны к 0 внутри топа платы и MUST NOT требовать пинов. `--load` MUST выполнить `load.sh`. Топ консоли MUST передать обёртке `USE_REGIO` равный 1 и MUST включить `regio.v` в список Verilog. Строка инстанса в `top.v` MUST содержать `.led(led)` одним токеном. `.qsf` MUST содержать `VERILOG_INCLUDE_FILE iomap.vh` и `HEX_FILE firmware.hex`. `iomap.vh` MUST NOT быть `VERILOG_FILE`.

#### Scenario: Terasic DE0-Nano
- **WHEN** в `projects/soc_terasic_de0nano` выполняется `fsoc --build`
- **THEN** `soc.qpf` содержит `PROJECT_REVISION = "soc"`, `soc.qsf` содержит `DEVICE EP4CE22F17C6`, `FAMILY "Cyclone IV E"`, `PIN_R8 -to clk`, `PIN_A15 -to led`, `PIN_B5 -to uart_tx`, `PIN_B4 -to uart_rx`, `VERILOG_FILE regio.v`, `VERILOG_INCLUDE_FILE iomap.vh` и `HEX_FILE firmware.hex`, `top.v` не имеет входов `rst` и `dump` в списке портов, не содержит `` `include ``, содержит `USE_REGIO(1)` и `.led(led)`, `firmware.hex` содержит 4096 строк, а Quartus не запускался

### Requirement: Делитель UART из частоты такта
Обёртка J1 MUST получать `CLK_HZ` и `BAUD` параметрами инстанса. Значение `CLK_HZ` MUST приходить от тактового ресурса, который запросила задача: у платы — из её описания, у эмуляции — из таргета. Эмуляция MUST вести UART тем же делителем, что стоит в `top.v`. Литерал делителя MUST NOT стоять ни в обёртке, ни в `main`, ни в тесте.

#### Scenario: Одна частота, два таргета
- **WHEN** собраны `projects/soc_emul` и `projects/soc_terasic_de0nano`
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

### Requirement: Консоль на эмуляции Colorlight
Проект `projects/soc_emul_colorlight_5a_75e_v6_0` MUST собираться задачей `soc`, таргетом `emulation`, платой `colorlight_5a_75e_v6_0` и дизайном `designs/soc_console.4th`. Топ MUST получить `CLK_HZ` тактового ресурса платы и `BAUD` 115200 и MUST сохранить порты `uart_rx`, `uart_tx`, `rst` и `dump`. Параметры `BOARD`, `NO_UART`, `LED_LOW` и `TIMER_DIV` MUST NOT попадать в этот топ. Сеанс `1 2 + .` MUST ответить `3` и ` ok`.

#### Scenario: Сеанс на 25 МГц
- **WHEN** в `projects/soc_emul_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** код возврата 0, журнал содержит `3` и ` ok`, `top.v` содержит `CLK_HZ(25000000)`, `BAUD(115200)` и `input wire uart_rx`, `sim.sh` содержит `CLK_HZ=25000000`, а `soc.lpf` и `soc.qsf` отсутствуют
