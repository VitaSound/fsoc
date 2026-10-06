# Spec Delta

## MODIFIED Requirements

### Requirement: Излучатель выбирается по CG
Профиль MUST хранить класс, строку FMAP, MM, EX-C, CG и BM. Сборка образа MUST вызывать излучатель, зарегистрированный для CG этого профиля. Профили `j1a` и `j1b` MUST иметь класс 0, MM=V, EX-C=V, CG=I, BM=C. Профиль `j1abs` MUST иметь класс 0, FMAP `V-V-A-0-I`, MM=V, EX-C=V, CG=I, BM=C, клетку 16 бит и порт образа `j1a`. Профиль `stm8` MUST иметь класс 1 и CG=E. Профиль `z80` MUST иметь класс 2, CG=F, клетку 16 бит и `cpu-ref` `cerberus-z80`. Профиль `avr` MUST иметь класс 1, MM=D, EX-C=S, CG=F и BM=C. Профиль `bcpu` MUST иметь класс 0, FMAP `U-M-B-A-3-F`, MM=U, EX-C=B, CG=F, BM=C, клетку 16 бит и `cpu-ref` `bcpu`. CG=E MUST NOT собирать hex. CG=F MUST писать Intel HEX только для `avr` при `s" fsys" sys:`. Для `bcpu` при `s" fsys" sys:` CG=F MUST писать слова по 16 бит (четыре hex-цифры на строку), а не Intel HEX. Для `z80` при `s" fsys" sys:` CG=F MUST писать байты (две hex-цифры на строку), а не Intel HEX. Для `avr` без `fsys` сборка MUST останавливаться до hex.

#### Scenario: Каркас без образа
- **WHEN** манифест содержит `s" stm8" cpu:`
- **THEN** сборка останавливается до запуска `gforth`, и в дереве нет скопированного `forth.asm`

#### Scenario: z80 пишет байт
- **WHEN** манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" z80" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` состоит из строк по две hex-цифры, в журнале есть `cerberus-z80(z80)`, `image tool: fsys` и `bytes of 16384`, и нет записи `:00000001FF`

### Requirement: Новый fsys-id входит в консольные тесты
Новый `cpu:` с консольным kernel и `s" fsys" sys:` MUST попасть в `tests/con_core_test.4th` (манифест в `tests/con_session.4th`, эталон JSON через `doc/j1-word-graph/build.py`, теги в `tests/con_words.py`). `accept` MUST стирать байты 8 и 127 той же семантикой, что у `j1a` / `j1b` / `avr`. Другой корпус того же ISA MUST NOT требовать новый ряд `con_core`. Профиль `j1abs` MUST NOT добавлять ряд `con_core`. Профиль `bcpu` с kernel fsys MUST входить в этот ряд. Профиль `msl16` с kernel fsys MUST входить в этот ряд. Профиль `z80` с kernel fsys MUST входить в этот ряд.

#### Scenario: z80 в консольных тестах
- **WHEN** в профилях есть `z80` и есть `fsys/kernel/z80`
- **THEN** `tests/con_core_test.4th` гоняет сеанс `z80`

### Requirement: MCU без SwapForth требует fsys
Пустое `sys:` MUST оставаться `swapforth`. Профиль без дерева SwapForth MUST требовать `s" fsys" sys:` и MUST останавливать сборку при пустом `sys:`. Профиль `z80` MUST требовать `s" fsys" sys:` и MUST писать byte-hex на 16384 байт, а не Intel HEX.

#### Scenario: z80 без fsys останавливается
- **WHEN** манифест содержит `s" z80" cpu:` без `sys:` и выполняется `fsoc --build`
- **THEN** сборка останавливается с текстом `needs fsys` и не читает `swapforth/`
