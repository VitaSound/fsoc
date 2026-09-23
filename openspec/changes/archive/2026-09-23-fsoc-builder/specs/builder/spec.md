# Spec Delta

## Purpose

Билдер fsoc собирает проект в текущем каталоге по флагам, как LiteX: задача и плата заданы скриптом проекта, а не аргументами команды.

## ADDED Requirements

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
