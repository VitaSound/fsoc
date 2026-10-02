# Spec Delta

## MODIFIED Requirements

### Requirement: Излучатель выбирается по CG
Профиль MUST хранить класс, строку FMAP, MM, EX-C, CG и BM. Сборка образа MUST вызывать излучатель, зарегистрированный для CG этого профиля. Профили `j1a` и `j1b` MUST иметь класс 0, MM=V, EX-C=V, CG=I, BM=C. Профиль `stm8` MUST иметь класс 1 и CG=E. Профиль `z80` MUST иметь класс 2 и CG=F. Профиль `avr` MUST иметь класс 1, MM=D, EX-C=N, CG=F и BM=C. CG=E MUST NOT собирать hex. CG=F MUST писать Intel HEX только для `avr`. Для `z80` сборка MUST останавливаться до hex.

#### Scenario: Каркас без образа
- **WHEN** манифест содержит `s" stm8" cpu:` или `s" z80" cpu:`
- **THEN** сборка останавливается до запуска `gforth`, и в дереве нет скопированного `forth.asm`

#### Scenario: ATmega8 пишет Intel HEX
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:` и `s" avr" cpu:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` — Intel HEX с записью `:00000001FF`, в журнале нет `gforth cross.fs`, и симулятор Proteus не запускается

#### Scenario: Текст blink
- **WHEN** к манифесту `avr` добавлено `s" blink" s" 1" option:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` содержит байты команды `ldi r16, 51` и байты `ldi r16, 'b'`
