# Spec Delta

## MODIFIED Requirements

### Requirement: Излучатель выбирается по CG
Профиль MUST хранить класс, строку FMAP, MM, EX-C, CG и BM. Сборка образа MUST вызывать излучатель, зарегистрированный для CG этого профиля. Профили `j1a` и `j1b` MUST иметь класс 0, MM=V, EX-C=V, CG=I, BM=C. Профиль `stm8` MUST иметь класс 1 и CG=E. Профиль `z80` MUST иметь класс 2 и CG=F. Профиль `avr` MUST иметь класс 1, MM=D, EX-C=S, CG=F и BM=C. Профиль `bcpu` MUST иметь класс 0, FMAP `U-M-B-A-3-F`, MM=U, EX-C=B, CG=F, BM=C, клетку 16 бит и `cpu-ref` `bcpu`. CG=E MUST NOT собирать hex. CG=F MUST писать Intel HEX только для `avr` при `s" fsys" sys:`. Для `bcpu` при `s" bcpu" sys:` CG=F MUST писать слова по 16 бит (четыре hex-цифры на строку), а не Intel HEX. Для `z80` сборка MUST останавливаться до hex. Для `avr` без `fsys` сборка MUST останавливаться до hex.

#### Scenario: Каркас без образа
- **WHEN** манифест содержит `s" stm8" cpu:` или `s" z80" cpu:`
- **THEN** сборка останавливается до запуска `gforth`, и в дереве нет скопированного `forth.asm`

#### Scenario: ATmega8 пишет Intel HEX
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:`, `s" avr" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` — Intel HEX с записью `:00000001FF`, в журнале нет `gforth cross.fs`, и симулятор Proteus не запускается

#### Scenario: Текст blink
- **WHEN** к манифесту `avr` с `s" fsys" sys:` добавлено `s" blink" s" 1" option:` и `s" image" s" release" option:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` содержит байты строки `blink on`

#### Scenario: bcpu пишет слово
- **WHEN** манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" bcpu" cpu:`, `s" bcpu" sys:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` состоит из строк по четыре hex-цифры, в журнале есть `bcpu(bcpu)` и `image tool: bcpu`, и нет записи `:00000001FF`

### Requirement: Новый fsys-id входит в консольные тесты
Новый `cpu:` с консольным kernel и `s" fsys" sys:` MUST попасть в `tests/con_core_test.4th` (манифест в `tests/con_session.4th`, эталон JSON через `doc/j1-word-graph/build.py`, теги в `tests/con_words.py`). `accept` MUST стирать байты 8 и 127 той же семантикой, что у `j1a` / `j1b` / `avr`. Другой корпус того же ISA MUST NOT требовать новый ряд `con_core`. Профиль `bcpu` с kernel fsys MUST входить в этот ряд. Инструкция агента: `.cursor/rules/fsoc-cpu-target.mdc`, навык `add-cpu-target`.

#### Scenario: Платформа без ряда con_core не принята
- **WHEN** добавляют новый id с `fsys` kernel и не трогают `con_core_test`
- **THEN** требование не выполнено: сеанс, `words` и теги для этого id отсутствуют

#### Scenario: bcpu в консольных тестах
- **WHEN** в профилях есть `bcpu` и есть `fsys/kernel/bcpu`
- **THEN** `tests/con_core_test.4th` гоняет сеанс `bcpu`

### Requirement: Сборка MCU ветвится по CG
Задача `soc` MUST выбирать излучатель по полю CG профиля. `fsoc/tasks/soc.4th` MUST NOT ветвить сборку по литералу id MCU (`avr`, `stm8`, `z80`, `bcpu` и любому следующему). Ветвление по CG MUST жить в уже зарегистрированном излучателе (`cg-f.4th` для CG=F, путь CG=I для J1). Новый CG=F с `fsys` MUST писать Intel HEX тем же излучателем CG=F. `bcpu` MUST ветвиться внутри `cg-f.4th` и MUST писать слово-образ, а не Intel HEX.

#### Scenario: soc.4th не знает MCU-профили
- **WHEN** читается `fsoc/tasks/soc.4th`
- **THEN** в нём нет литерала `avr`, нет литерала `stm8` и нет литерала `bcpu` как ветвления сборки образа

### Requirement: MCU без SwapForth требует fsys
Пустое `sys:` MUST оставаться `swapforth`. Профиль без дерева SwapForth и без собственного имени `sys:` MUST требовать `s" fsys" sys:` и MUST останавливать сборку при пустом `sys:`. Профиль `bcpu` MUST требовать `s" bcpu" sys:` и MUST останавливать сборку до образа SwapForth, если `sys:` пуст или равен `swapforth`. CG=E MUST NOT писать hex, пока профиль не сменит CG.

#### Scenario: AVR без fsys останавливается
- **WHEN** манифест содержит `s" avr" cpu:` без `sys:` и выполняется `fsoc --build`
- **THEN** сборка останавливается до записи hex

#### Scenario: bcpu без своего sys останавливается
- **WHEN** манифест содержит `s" bcpu" cpu:` без `sys:` и выполняется `fsoc --build`
- **THEN** сборка останавливается с текстом `needs bcpu` и не читает `swapforth/`
