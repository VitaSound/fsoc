# Spec Delta

## MODIFIED Requirements

### Requirement: Излучатель выбирается по CG
Профиль MUST хранить класс, строку FMAP, MM, EX-C, CG и BM. Сборка образа MUST вызывать излучатель, зарегистрированный для CG этого профиля. Профили `j1a` и `j1b` MUST иметь класс 0, MM=V, EX-C=V, CG=I, BM=C. Профиль `j1abs` MUST иметь класс 0, FMAP `V-V-A-0-I`, MM=V, EX-C=V, CG=I, BM=C, клетку 16 бит и порт образа `j1a`. Профиль `stm8` MUST иметь класс 1 и CG=E. Профиль `z80` MUST иметь класс 2 и CG=F. Профиль `avr` MUST иметь класс 1, MM=D, EX-C=S, CG=F и BM=C. CG=E MUST NOT собирать hex. CG=F MUST писать Intel HEX только для `avr` при `s" fsys" sys:`. Для `z80` сборка MUST останавливаться до hex. Для `avr` без `fsys` сборка MUST останавливаться до hex.

#### Scenario: Каркас без образа
- **WHEN** манифест содержит `s" stm8" cpu:` или `s" z80" cpu:`
- **THEN** сборка останавливается до запуска `gforth`, и в дереве нет скопированного `forth.asm`

#### Scenario: ATmega8 пишет Intel HEX
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:`, `s" avr" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` — Intel HEX с записью `:00000001FF`, в журнале нет `gforth cross.fs`, и симулятор Proteus не запускается

#### Scenario: Текст blink
- **WHEN** к манифесту `avr` с `s" fsys" sys:` добавлено `s" blink" s" 1" option:` и `s" image" s" release" option:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` содержит байты строки `blink on`

#### Scenario: j1abs берёт образ j1a
- **WHEN** манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" j1abs" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** журнал содержит `fsys/kernel/j1a/kernel.4th`, скопированный `j1.v` содержит `alu_rom`, и `tests/con_core_test.4th` не содержит ряда `j1abs`

### Requirement: Новый fsys-id входит в консольные тесты
Новый `cpu:` с консольным kernel и `s" fsys" sys:` MUST попасть в `tests/con_core_test.4th` (манифест в `tests/con_session.4th`, эталон JSON через `doc/j1-word-graph/build.py`, теги в `tests/con_words.py`). `accept` MUST стирать байты 8 и 127 той же семантикой, что у `j1a` / `j1b` / `avr`. Другой корпус того же ISA MUST NOT требовать новый ряд `con_core`. Профиль `j1abs` MUST NOT добавлять ряд `con_core`: это тот же ISA, что `j1a`, и образ читается через порт `j1a`. Инструкция агента: `.cursor/rules/fsoc-cpu-target.mdc`, навык `add-cpu-target`.

#### Scenario: Платформа без ряда con_core не принята
- **WHEN** добавляют новый id с `fsys` kernel и не трогают `con_core_test`
- **THEN** требование не выполнено: сеанс, `words` и теги для этого id отсутствуют

#### Scenario: j1abs без своего ряда
- **WHEN** в профилях есть `j1abs`
- **THEN** `tests/con_core_test.4th` не содержит ряда `j1abs`

### Requirement: Сборка MCU ветвится по CG
Задача `soc` MUST выбирать излучатель по полю CG профиля. `fsoc/tasks/soc.4th` MUST NOT ветвить сборку по литералу id MCU (`avr`, `stm8`, `z80`, `j1abs` и любому следующему). Ветвление по CG MUST жить в уже зарегистрированном излучателе (`cg-f.4th` для CG=F, путь CG=I для J1). Новый CG=F с `fsys` MUST писать Intel HEX тем же излучателем CG=F.

#### Scenario: soc.4th не знает MCU-профили
- **WHEN** читается `fsoc/tasks/soc.4th`
- **THEN** в нём нет литерала `avr`, нет литерала `stm8` и нет литерала `j1abs` как ветвления сборки образа

## ADDED Requirements

### Requirement: Порт образа
Профиль MAY задавать `cpu-port`. Пустое поле MUST означать id профиля. `soc-port` MUST возвращать этот порт. Каталог образа SwapForth и kernel fsys MUST строиться от порта, а не от id, когда порт задан.

#### Scenario: Пустой порт
- **WHEN** у профиля `j1a` порт не задан
- **THEN** `soc-port` для этого профиля равен `j1a`

#### Scenario: j1abs указывает на j1a
- **WHEN** читается профиль `j1abs`
- **THEN** его порт образа равен `j1a`
