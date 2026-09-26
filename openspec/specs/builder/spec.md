# builder Specification

## Purpose

Билдер fsoc собирает проект в текущем каталоге по флагам, как LiteX: задача и плата заданы скриптом проекта, а не аргументами команды.

## Requirements

### Requirement: Запуск из каталога проекта
Билдер MUST выполняться в текущем каталоге и MUST NOT переходить в корень репозитория. Идентичность проекта MUST читаться из `target.4th` в этом каталоге.

#### Scenario: Сборка эмуляции blinky
- **WHEN** в `projects/blinky_emul` выполняется `fsoc --build`
- **THEN** в этом каталоге появляются `top.v`, `blinky.v` и `sim.sh`, Verilator компилируется и реалтайм-просмотр идёт до Ctrl+C

#### Scenario: Сборка платы
- **WHEN** в `projects/blinky_rz_easyfpga` выполняется `fsoc --build`
- **THEN** в этом каталоге появляются `top.v`, `blinky.qsf`, `blinky.sdc`, `build.sh` и `load.sh`, а Quartus не запускается

### Requirement: Флаги build и load независимы
`fsoc --build --load` MUST сначала выполнить сборку, затем прошивку. На эмуляции `--load` MUST игнорироваться без ошибки. На проекте с платой `--load` MUST запустить `load.sh`.

#### Scenario: Оба флага на плате
- **WHEN** в `projects/blinky_vitasound_ep4ce10` выполняется `fsoc --build --load`
- **THEN** сначала записываются файлы проекта, затем выполняется `load.sh`

#### Scenario: Load на эмуляции
- **WHEN** в `projects/blinky_emul` выполняется `fsoc --build --load`
- **THEN** сборка и реалтайм-просмотр идут как при одном `--build`, а `--load` ничего не печатает как ошибку и не меняет код возврата

### Requirement: Диспетчер не знает имя задачи
Команда MUST NOT содержать ветку по имени blinky. Слово сборки MUST выводиться из поля задачи в `target.4th`.

#### Scenario: Неизвестная задача
- **WHEN** `target.4th` называет задачу, для которой нет слова сборки
- **THEN** билдер завершается с ошибкой и не создаёт `top.v`

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
