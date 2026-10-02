# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Приложение blink вне fsys
`firmware/blink.fs` MUST оставаться вне fsys. Билдер MUST дописать его только при `s" blink" s" 1" option:` и только если инструмент оставил Форт, который может этот файл загрузить.

#### Scenario: Консоль без blink
- **WHEN** манифест AVR с `s" fsys" sys:` без опции `blink`
- **THEN** в `firmware.hex` нет последовательности байт текста `blink on`
