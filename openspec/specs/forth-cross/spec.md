# forth-cross Specification

## Purpose

Профили Forth для сборки образа: поле манифеста `cpu:` выбирает профиль, а излучатель берётся из его кода CG, не из имени тулчейна платы.

## Requirements

### Requirement: Профиль называется полем cpu
Манифест MAY содержать `s" <id>" cpu:`. Задача `soc` MUST собирать образ излучателем этого профиля. Имя тулчейна (`quartus`, `yosys`, `emulation`) MUST NOT выбирать профиль. Неизвестный id MUST останавливать сборку и MUST NOT подставлять `j1a`. Пустое поле у существующих проектов MUST означать `j1a`. Id процессора MUST выбирать подкаталог внутри уже выбранного `sys:`, а не каталог под `cpu/j1/`.

#### Scenario: Неизвестный профиль
- **WHEN** манифест содержит `s" no-such-cpu" cpu:` и выполняется `fsoc --build`
- **THEN** сборка останавливается с текстом, содержащим `no-such-cpu`, и каталог `swapforth/j1a` не используется

#### Scenario: Пустое поле
- **WHEN** `projects/soc_emul/target.4th` не содержит `cpu:` и выполняется сборка образа
- **THEN** кросс читает `swapforth/j1a/nuc.fs`

### Requirement: Излучатель выбирается по CG
Профиль MUST хранить класс, строку FMAP, MM, EX-C, CG и BM. Сборка образа MUST вызывать излучатель, зарегистрированный для CG этого профиля. Профили `j1a` и `j1b` MUST иметь класс 0, MM=V, EX-C=V, CG=I, BM=C. Профиль `stm8` MUST иметь класс 1 и CG=E. Профиль `z80` MUST иметь класс 2 и CG=F. CG=E и CG=F MUST NOT собирать hex в этом срезе.

#### Scenario: Каркас без образа
- **WHEN** манифест содержит `s" stm8" cpu:` или `s" z80" cpu:`
- **THEN** сборка останавливается до запуска `gforth`, и в дереве нет скопированного `forth.asm`

### Requirement: J1B не затирает J1a
Исходники J1B MUST быть взяты из каталога `original/j1b` репозитория wzab/AFCK_J1B_FORTH: `cross.fs`, `basewords.fs`, `nuc.fs`, `swapforth.fs`, `verilog/j1.v`, `verilog/stack.v`, `verilog/common.h`. Файл ядра в fsoc MUST называться `j1b.v` и лежать в комплекте `cpu/j1/j1b/`. Существующий `cpu/j1/j1a/j1.v` MUST остаться с `` `define WIDTH 16 ``. VHDL, I2C и проект Vivado платы AFCK MUST NOT копироваться. Рядом MUST лежать текст лицензии BSD Боумана.

#### Scenario: Оба ядра на диске
- **WHEN** профиль `j1b` зарегистрирован
- **THEN** `cpu/j1/j1a/j1.v` содержит `WIDTH 16`, `cpu/j1/j1b/j1b.v` содержит ширину 32, а в репозитории нет `j1.vhd` из каталога `src/j1b`

### Requirement: Обёртка J1B отдельная
16-битная `j1_wrap.v` MUST NOT инстанциировать ядро ширины 32. Комплект `j1b` MUST называть файл обёртки с `WIDTH 32` и портом `mem_din`. Сборка с `cpu:` равным `j1b` MUST собирать образ этого комплекта и MUST NOT подставлять hex j1a.

#### Scenario: j1b со своим комплектом
- **WHEN** манифест содержит `s" j1b" cpu:` и выполняется сборка консоли
- **THEN** `includes.lst` содержит `j1b.v`, `stack.v`, `common.h` и `j1b_wrap.v`, `firmware.hex` содержит 8192 строки по 8 hex-цифр, и этот файл не совпадает с образом j1a

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
