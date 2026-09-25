# Spec Delta

## ADDED Requirements

### Requirement: Консоль не знает прошивку
`emu/con` MUST печатать байт и смену уровня и MUST NOT искать в потоке UART текст прошивки, MUST NOT считать переключения пина ради завершения и MUST NOT знать имён из иерархии дизайна. Решение о завершении прогона MUST принимать библиотека такта по пределам `FSOC_EMU_*`, а проверка содержимого журнала — тест.

#### Scenario: Журнал лампы без оракула в консоли
- **WHEN** в `projects/soc_blink` запущен просмотр с `FSOC_EMU_CON=term`, `FSOC_EMU_FAST=1`, `FSOC_EMU_CYCLES=200000`
- **THEN** вывод содержит `lamp on` и `lamp off`, а `rg "lamp" emu/ fsoc/tasks/*.cpp` пусто
