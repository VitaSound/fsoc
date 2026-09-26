# Spec Delta

## MODIFIED Requirements

### Requirement: Запуск из каталога проекта
Билдер MUST выполняться в текущем каталоге и MUST NOT переходить в корень репозитория. Идентичность проекта MUST читаться из `target.4th` в этом каталоге словами манифеста: `s" <задача>" task:`, `s" <таргет>" target:`, `s" <плата>" board:` (пустая строка — без платы), `s" <путь>" design:`, `s" <имя>" s" <значение>" option:`. Слова манифеста MUST жить в ядре билдера и MUST NOT быть словами задачи. Билдер MUST остановиться с ошибкой, если `task:` или `target:` отсутствуют.

#### Scenario: Сборка эмуляции blinky
- **WHEN** в `projects/blinky_emul` лежит `target.4th` со строками `s" blinky" task:` и `s" emulation" target:` и выполняется `fsoc --build`
- **THEN** в этом каталоге появляются `top.v`, `blinky.v` и `sim.sh`, Verilator компилируется и реалтайм-просмотр идёт до Ctrl+C

#### Scenario: Сборка платы
- **WHEN** в `projects/blinky_terasic_de0nano` лежит `target.4th` со строками `s" blinky" task:`, `s" quartus" target:`, `s" terasic_de0nano" board:` и выполняется `fsoc --build`
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
- **WHEN** в `projects/blinky_terasic_de0nano` выполняется `fsoc --build --load`
- **THEN** сначала записываются файлы проекта, затем выполняется `load.sh`

#### Scenario: Load на эмуляции
- **WHEN** в `projects/blinky_emul` выполняется `fsoc --build --load`
- **THEN** сборка и реалтайм-просмотр идут как при одном `--build`, а `--load` ничего не печатает как ошибку и не меняет код возврата

### Requirement: Очистка каталога проекта
`fsoc --clean` MUST удалить из текущего каталога всё, кроме `target.4th`. Если этого файла нет, команда MUST завершиться с ошибкой `no target.4th` и MUST NOT удалять соседние файлы. `fsoc --clean --build` MUST сначала очистить каталог, затем выполнить сборку.

#### Scenario: Очистка после сборки платы
- **WHEN** в каталоге с манифестом `blinky_terasic_de0nano` после `fsoc --build` выполняется `fsoc --clean`
- **THEN** `target.4th` остаётся, а `top.v` и `blinky.qsf` отсутствуют

#### Scenario: Нет манифеста
- **WHEN** в каталоге нет `target.4th` и выполняется `fsoc --clean`
- **THEN** команда завершается с ошибкой `no target.4th`, а прочие файлы каталога остаются

### Requirement: Задача SoC на таргете платы
Задача `soc` MUST собираться на зарегистрированном таргете без сравнения имени таргета со строками `quartus`, `emulation` или `yosys`. При заданной плате задача MUST загрузить её, запросить единственный тактовый ресурс (`plat-clock`) и `user_led`, и MUST запросить `serial` только когда `s" serial" 0 io-find` его находит. Таргет `quartus` MUST записать `.qsf` из карты пинов. Таргет `emulation` MUST карту игнорировать. Таргет `yosys` MUST записать `.lpf` из той же карты.

#### Scenario: Один и тот же дизайн на двух таргетах
- **WHEN** `projects/soc_emul` и `projects/soc_terasic_de0nano` называют `designs/soc_console.4th` и выполняется `fsoc --build` в каждом
- **THEN** первый каталог содержит `sim.sh` и не содержит `.qsf`, второй содержит `soc.qsf` и не содержит `sim.sh`

#### Scenario: Лампа на Yosys
- **WHEN** в `projects/soc_blink_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_SYNTH_SKIP=1`
- **THEN** каталог содержит `soc.lpf` и не содержит `sim.sh` и `soc.qsf`
