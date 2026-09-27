# Spec Delta

## MODIFIED Requirements

### Requirement: Запуск из каталога проекта
Билдер MUST выполняться в текущем каталоге и MUST NOT переходить в корень репозитория. Идентичность проекта MUST читаться из `target.4th` в этом каталоге словами манифеста: `s" <задача>" task:`, `s" <таргет>" target:`, `s" <плата>" board:` (пустая строка — без платы), `s" <путь>" design:`, `s" <id>" cpu:`, `s" <id>" sys:`, `s" <имя>" s" <значение>" option:`. Слова манифеста MUST жить в ядре билдера и MUST NOT быть словами задачи. Билдер MUST остановиться с ошибкой, если `task:` или `target:` отсутствуют. Пустое `sys:` MUST NOT быть ошибкой и MUST означать `swapforth`. Неизвестный id в `sys:` MUST останавливать сборку до кросса.

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

#### Scenario: Пустое sys не ошибка
- **WHEN** `target.4th` задачи `soc` не содержит `sys:` и выполняется `fsoc --build`
- **THEN** сборка не останавливается из-за отсутствия `sys:` и читает инструмент `swapforth`

#### Scenario: Неизвестный sys
- **WHEN** `target.4th` содержит `s" no-such-sys" sys:` и выполняется `fsoc --build`
- **THEN** билдер завершается с ошибкой, содержащей `no-such-sys`, до запуска кросса
