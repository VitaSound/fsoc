## ADDED Requirements

### Requirement: Профиль 8051
Профиль `8051` MUST иметь класс 1, FMAP `D-S-A-M-3-F`, MM=D, EX-C=S, CG=F, BM=C, клетку 16 бит и `cpu-ref` `at89c52`. Option `body` soft|hard MUST выбирать soft leaf или hard HEX. Пустой `body` MUST означать soft для `emulation`/`yosys` и hard для `proteus`.

#### Scenario: Soft пишет byte hex
- **WHEN** манифест содержит `s" soc" task:`, `s" emulation" target:`, `s" 8051" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` состоит из строк по две hex-цифры, в журнале есть `at89c52(8051)` и `image tool: fsys`, и нет записи `:00000001FF`

#### Scenario: Hard пишет Intel HEX
- **WHEN** манифест содержит `s" soc" task:`, `s" proteus" target:`, `s" 8051" cpu:`, `s" fsys" sys:` и выполняется `fsoc --build`
- **THEN** `firmware.hex` — Intel HEX с записью `:00000001FF`, и журнал предлагает открыть его в Proteus
