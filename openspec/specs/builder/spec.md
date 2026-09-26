# builder Specification

## Purpose

Билдер fsoc собирает проект в текущем каталоге по флагам, как LiteX: задача и плата заданы скриптом проекта, а не аргументами команды.

## Requirements

### Requirement: Запуск из каталога проекта
Билдер MUST выполняться в текущем каталоге и MUST NOT переходить в корень репозитория. Идентичность проекта MUST читаться из `target.4th` в этом каталоге словами манифеста: `s" <задача>" task:`, `s" <таргет>" target:`, `s" <плата>" board:` (пустая строка — без платы), `s" <путь>" design:`, `s" <имя>" s" <значение>" option:`. Слова манифеста MUST жить в ядре билдера и MUST NOT быть словами задачи. Билдер MUST остановиться с ошибкой, если `task:` или `target:` отсутствуют.

#### Scenario: Сборка эмуляции blinky
- **WHEN** в `projects/blinky_emul` лежит `target.4th` со строками `s" blinky" task:` и `s" emulation" target:` и выполняется `fsoc --build`
- **THEN** в этом каталоге появляются `top.v`, `blinky.v` и `sim.sh`, Verilator компилируется и реалтайм-просмотр идёт до Ctrl+C

#### Scenario: Сборка платы
- **WHEN** в `projects/blinky_rz_easyfpga` лежит `target.4th` со строками `s" blinky" task:`, `s" quartus" target:`, `s" rz_easyfpga" board:` и выполняется `fsoc --build`
- **THEN** в этом каталоге появляются `top.v`, `blinky.qpf`, `blinky.qsf`, `blinky.sdc`, `build.sh` и `load.sh`, а Quartus не запускается

#### Scenario: Опция проекта
- **WHEN** `target.4th` проекта `soc_blink` содержит `s" lamp" s" 1" option:`
- **THEN** сборка дописывает в образ цикл лампы, а `target.4th` не содержит слова с именем задачи

#### Scenario: Манифест без таргета
- **WHEN** `target.4th` содержит только `s" blinky" task:`
- **THEN** билдер завершается с ошибкой до записи файлов, и `top.v` не создан

### Requirement: Флаги build и load независимы
`fsoc --build --load` MUST сначала выполнить сборку, затем прошивку. На эмуляции `--load` MUST игнорироваться без ошибки. На проекте с платой `--load` MUST запустить `load.sh`.

#### Scenario: Оба флага на плате
- **WHEN** в `projects/blinky_vitasound_ep4ce10` выполняется `fsoc --build --load`
- **THEN** сначала записываются файлы проекта, затем выполняется `load.sh`

#### Scenario: Load на эмуляции
- **WHEN** в `projects/blinky_emul` выполняется `fsoc --build --load`
- **THEN** сборка и реалтайм-просмотр идут как при одном `--build`, а `--load` ничего не печатает как ошибку и не меняет код возврата

### Requirement: Диспетчер не знает имя задачи
Команда MUST NOT содержать ветку по имени задачи или таргета и MUST NOT склеивать имя слова сборки из суффикса. Задача MUST регистрироваться в реестре словом `task-register` со своим словом сборки `( project -- )`; таргет MUST регистрироваться словом `target-register` со словами `emit`, `run`, `load` `( project -- )`. Слова манифеста `task:` / `target:` и слова реестра MUST быть разными словами. `--build` MUST выполнить слово сборки задачи, затем `emit` таргета, затем `run` таргета. `--load` MUST выполнить `load` таргета. Неизвестное имя задачи или таргета MUST останавливать билдер до любого `emit`.

#### Scenario: Неизвестная задача
- **WHEN** `target.4th` называет задачу, для которой нет записи в реестре
- **THEN** билдер завершается с ошибкой и не создаёт `top.v`

#### Scenario: Неизвестный таргет
- **WHEN** `target.4th` называет таргет `nosuch`
- **THEN** билдер завершается с ошибкой и не создаёт `top.v`

#### Scenario: CLI без слов задач
- **WHEN** читается `fsoc.4th`
- **THEN** в файле нет слов с префиксом `blinky-` или `soc-`, нет литералов `-emit-emulation`, `-on-board`, `sim.sh`, `load.sh`

### Requirement: Очистка каталога проекта
`fsoc --clean` MUST удалить из текущего каталога всё, кроме `target.4th`. Если этого файла нет, команда MUST завершиться с ошибкой `no target.4th` и MUST NOT удалять соседние файлы. `fsoc --clean --build` MUST сначала очистить каталог, затем выполнить сборку.

#### Scenario: Очистка после сборки платы
- **WHEN** в каталоге с манифестом `blinky_rz_easyfpga` после `fsoc --build` выполняется `fsoc --clean`
- **THEN** `target.4th` остаётся, а `top.v` и `blinky.qsf` отсутствуют

#### Scenario: Нет манифеста
- **WHEN** в каталоге нет `target.4th` и выполняется `fsoc --clean`
- **THEN** команда завершается с ошибкой `no target.4th`, а прочие файлы каталога остаются

### Requirement: Таргет yosys запускает синтез
Для таргета `yosys` команда `--build` MUST записать `<project>.lpf`, `build.sh` и `load.sh`, затем запустить `sh build.sh`. Если `yosys` и `nextpnr-ecp5` уже есть в `PATH`, скрипт запускается ими. Иначе, когда установлен `~/oss-cad-suite`, запуск MUST подключить `environment` этого набора. Непустой `FSOC_SYNTH_SKIP` MUST пропустить инструменты и всё равно записать файлы. `--load` MUST запустить `load.sh`. Без опции `cable` этот скрипт MUST завершаться с текстом `yosys: no cable option`.

#### Scenario: Colorlight V6.0 без синтеза
- **WHEN** проект `blinky_colorlight_5a_75e_v6_0` собирается с `FSOC_SYNTH_SKIP=1`
- **THEN** `blinky.lpf` содержит `SITE "P6"`, `SITE "T6"` и `FREQUENCY PORT "clk" 25.000 MHz`, `build.sh` содержит `synth_ecp5` и `nextpnr-ecp5 --25k --package CABGA256 --speed 6`, а `load.sh` содержит `yosys: no cable option`

### Requirement: Три ревизии Colorlight 5A-75E
Платы `colorlight_5a_75e_v6_0`, `colorlight_5a_75e_v7_1` и `colorlight_5a_75e_v8_2` MUST загружаться. У v6.0 и v7.1 устройство MUST быть `LFE5U-25F-6BG256C`, speed MUST быть `6`. У v8.2 устройство MUST быть `LFE5U-25F-7BG256I`, speed MUST быть `7`. У всех пакет MUST быть `CABGA256`, плотность `25k`, такт 25 МГц на пине `P6`. Светодиод v6.0 и v8.2 MUST быть `T6`, у v7.1 — `P11`. Кнопка v6.0 и v8.2 MUST быть `R7`, у v7.1 — `M13`.

#### Scenario: Пины трёх ревизий
- **WHEN** загружены три платы Colorlight 5A-75E
- **THEN** у каждой один такт 25000000 Гц на `P6`, светодиод v7.1 сидит на `P11`, а устройство v8.2 — `LFE5U-25F-7BG256I`

### Requirement: Пути от FSOC_HOME
Библиотека MUST находить файлы репозитория (`rtl/`, `cpu/`, `emu/`, `firmware/`, `designs/`, `boards/`, `fsoc/`) только через `FSOC_HOME`. Слово MUST NOT пробовать несколько относительных префиксов, чтобы угадать каталог вызывающего. Каталог проекта MUST читаться один раз как текущий каталог и передаваться дальше в манифесте. Без `FSOC_HOME` билдер MUST остановиться с сообщением об этом.

#### Scenario: Один и тот же лист из проекта и из теста
- **WHEN** `fsoc --build` запущен из `projects/blinky_emul`, а `fmix test` из корня репозитория, и оба задают `FSOC_HOME`
- **THEN** в обоих случаях скопирован `rtl/blinky.v` из `FSOC_HOME`, и `cmp` копии с оригиналом успешен

#### Scenario: FSOC_HOME не задан
- **WHEN** `fsoc --build` запущен без `FSOC_HOME`
- **THEN** билдер печатает `FSOC_HOME unset` и не создаёт файлов

### Requirement: Общие операции в ядре
Копирование файла, создание каталога, запуск команды оболочки с проверкой кода возврата, строка лога `fsoc: <проект> - <текст>` и загрузка платы по имени MUST быть словами ядра билдера. Задача MUST NOT определять собственные варианты этих слов. Обход списков MUST использовать публичный API `fenum` (`ulist-each`, `ulist-len`, `ulist-nth-addr`), а не внутренние узлы.

#### Scenario: Нет дублей между задачами
- **WHEN** выполняется `flint lint . --strict --project-only`
- **THEN** предупреждений нет, и `rg "pick3|ulist-head|unode-" fsoc/ targets/ designs/` пусто

#### Scenario: Лог сборки одинаков для задач
- **WHEN** выполняется `fsoc --build` в `projects/blinky_emul` и в `projects/soc_emul`
- **THEN** оба лога начинаются со строки `fsoc: <имя каталога> - Start build`

### Requirement: Тесты не трогают рабочие каталоги
Тест билдера MUST копировать `target.4th` проекта во временный каталог и запускать `fsoc` там. Тест MUST NOT удалять и MUST NOT перезаписывать файлы в `projects/*`. В конце тестового файла стек данных MUST быть пуст.

#### Scenario: Проект пользователя цел
- **WHEN** в `projects/soc_emul` лежат `top.v` и `obj_dir/` от ручной сборки и выполняется `fmix test`
- **THEN** после теста эти файлы на месте с прежним временем изменения

#### Scenario: Чистый стек
- **WHEN** выполняется любой файл `tests/*_test.4th`
- **THEN** последнее утверждение `expect-stack-clean` проходит

### Requirement: Задача SoC на таргете платы
Задача `soc` MUST собираться на зарегистрированном таргете без сравнения имени таргета со строками `quartus`, `emulation` или `yosys`. При заданной плате задача MUST загрузить её, запросить единственный тактовый ресурс (`plat-clock`) и `user_led`, и MUST запросить `serial` только когда `s" serial" 0 io-find` его находит. Таргет `quartus` MUST записать `.qsf` из карты пинов. Таргет `emulation` MUST карту игнорировать. Таргет `yosys` MUST записать `.lpf` из той же карты.

#### Scenario: Один и тот же дизайн на двух таргетах
- **WHEN** `projects/soc_emul` и `projects/soc_vitasound_ep4ce10` называют `designs/soc_console.4th` и выполняется `fsoc --build` в каждом
- **THEN** первый каталог содержит `sim.sh` и не содержит `.qsf`, второй содержит `soc.qsf` и не содержит `sim.sh`

#### Scenario: Лампа на Yosys
- **WHEN** в `projects/soc_blink_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_SYNTH_SKIP=1`
- **THEN** каталог содержит `soc.lpf` и не содержит `sim.sh` и `soc.qsf`
