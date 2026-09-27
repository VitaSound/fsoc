## ADDED Requirements

### Requirement: Профиль называется полем cpu
Манифест MAY содержать `s" <id>" cpu:`. Задача `soc` MUST собирать образ излучателем этого профиля. Имя тулчейна (`quartus`, `yosys`, `emulation`) MUST NOT выбирать профиль. Неизвестный id MUST останавливать сборку и MUST NOT подставлять `j1a`. Пустое поле у существующих проектов MUST означать `j1a`.

#### Scenario: Неизвестный профиль
- **WHEN** манифест содержит `s" no-such-cpu" cpu:` и выполняется `fsoc --build`
- **THEN** сборка останавливается с текстом, содержащим `no-such-cpu`, и каталог `cpu/j1/swapforth/j1a` не используется

#### Scenario: Пустое поле
- **WHEN** `projects/soc_emul/target.4th` не содержит `cpu:` и выполняется сборка образа
- **THEN** кросс читает `cpu/j1/swapforth/j1a/nuc.fs`

### Requirement: Излучатель выбирается по CG
Профиль MUST хранить класс, строку FMAP, MM, EX-C, CG и BM. Сборка образа MUST вызывать излучатель, зарегистрированный для CG этого профиля. Профили `j1a` и `j1b` MUST иметь класс 0, MM=V, EX-C=V, CG=I, BM=C. Профиль `stm8` MUST иметь класс 1 и CG=E. Профиль `z80` MUST иметь класс 2 и CG=F. CG=E и CG=F MUST NOT собирать hex в этом срезе.

#### Scenario: Каркас без образа
- **WHEN** манифест содержит `s" stm8" cpu:` или `s" z80" cpu:`
- **THEN** сборка останавливается до запуска `gforth`, и в дереве нет скопированного `forth.asm`

### Requirement: J1B не затирает J1a
Исходники J1B MUST быть взяты из каталога `original/j1b` репозитория wzab/AFCK_J1B_FORTH: `cross.fs`, `basewords.fs`, `nuc.fs`, `swapforth.fs`, `verilog/j1.v`, `verilog/stack.v`, `verilog/common.h`. Файл ядра в fsoc MUST называться `j1b.v`. Существующий `cpu/j1/j1.v` MUST остаться с `` `define WIDTH 16 ``. VHDL, I2C и проект Vivado платы AFCK MUST NOT копироваться. Рядом MUST лежать текст лицензии BSD Боумана.

#### Scenario: Оба ядра на диске
- **WHEN** профиль `j1b` зарегистрирован
- **THEN** `cpu/j1/j1.v` содержит `WIDTH 16`, `cpu/j1/j1b.v` содержит ширину 32, а в репозитории нет `j1.vhd` из каталога `src/j1b`

### Requirement: Обёртка J1B отдельная
16-битная `j1_wrap.v` MUST NOT инстанциировать ядро ширины 32. Сборка с `cpu:` равным `j1b` MUST останавливаться, пока нет обёртки WIDTH 32 с портом чтения памяти, и MUST NOT молча собирать образ j1a.

#### Scenario: j1b без обёртки
- **WHEN** манифест содержит `s" j1b" cpu:` и обёртки ширины 32 нет
- **THEN** сборка останавливается с текстом, содержащим `j1b`, и `firmware.hex` не совпадает с образом j1a
