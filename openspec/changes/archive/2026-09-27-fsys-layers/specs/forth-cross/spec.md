# Spec Delta

## MODIFIED Requirements

### Requirement: Профиль называется полем cpu
Манифест MAY содержать `s" <id>" cpu:`. Задача `soc` MUST собирать образ излучателем этого профиля. Имя тулчейна (`quartus`, `yosys`, `emulation`) MUST NOT выбирать профиль. Неизвестный id MUST останавливать сборку и MUST NOT подставлять `j1a`. Пустое поле у существующих проектов MUST означать `j1a`. Id процессора MUST выбирать подкаталог внутри уже выбранного `sys:`, а не каталог под `cpu/j1/`.

#### Scenario: Неизвестный профиль
- **WHEN** манифест содержит `s" no-such-cpu" cpu:` и выполняется `fsoc --build`
- **THEN** сборка останавливается с текстом, содержащим `no-such-cpu`, и каталог `swapforth/j1a` не используется

#### Scenario: Пустое поле
- **WHEN** `projects/soc_emul/target.4th` не содержит `cpu:` и выполняется сборка образа
- **THEN** кросс читает `swapforth/j1a/nuc.fs`

## ADDED Requirements

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
