# Spec Delta

## ADDED Requirements

### Requirement: Blinky на AVR пишет HEX без Forth
Задача `blinky` с `cpu:` AVR MUST собрать текст `[asm]` из `firmware/blink_avr.4th` словами fasm, MUST записать `firmware.hex` и MUST NOT включать kernel, `quit` и `s" fsys" sys:`. Каталог рабочего проекта MUST быть `projects/baremetal/blinky_atmega`. Имя задачи MUST быть `blinky`; fasm MUST остаться инструментом в журнале (`image tool: fasm`).

#### Scenario: Голый AVR без quit
- **WHEN** манифест содержит `s" blinky" task:`, `s" proteus" target:`, `s" avr" cpu:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` оканчивается на `:00000001FF`, в журнале есть `image tool: fasm` и нет имени `quit` в образе

### Requirement: Ядро не есть файл blink_avr
`firmware/blink_avr.4th` MUST NOT лежать в `fsys/kernel/` и MUST NOT лежать в `fsys/fasm/`.

#### Scenario: Мигалка вне kernel
- **WHEN** читается дерево `fsys/kernel/avr/`
- **THEN** в нём нет `blink.4th`
