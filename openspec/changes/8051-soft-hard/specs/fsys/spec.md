## ADDED Requirements

### Requirement: Консоль 8051 в con_core
Профиль `8051` с kernel fsys MUST входить в `tests/con_core_test.4th` на soft-теле (Verilator). `accept` MUST стирать байты 8 и 127. Hard MAY проверяться через `tools/8051-con` (s51) с skip при отсутствии `s51`.

#### Scenario: Soft con_core
- **WHEN** в профилях есть `8051` и есть `fsys/kernel/8051`
- **THEN** `tests/con_core_test.4th` гоняет сеанс soft `8051`
