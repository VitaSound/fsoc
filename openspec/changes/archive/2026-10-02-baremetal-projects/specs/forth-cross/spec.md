# Spec Delta

## ADDED Requirements

### Requirement: AVR печатает Hardware и Software
Сборка образа AVR MUST напечатать `Start build`, `Hardware`, строку `atmega8(avr)`, `Hardware complete`, `Software`, `image tool: fsys` или `image tool: fasm`, пути собранных исходников, `firmware.hex: <байт> bytes of <ёмкость flash>`, `Software complete`. Ёмкость MUST быть `avr-flash` в байтах (у ATmega8 — 8192). Строка `ATmega8 Intel HEX` MUST NOT печататься.

#### Scenario: Консоль AVR называет чип и размер
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:`, `s" avr" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** в журнале есть `atmega8(avr)`, `image tool: fsys` и `bytes of 8192`
