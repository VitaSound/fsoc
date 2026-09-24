# Spec Delta

## MODIFIED Requirements

### Requirement: Канал uart того же вида
Канал UART MUST оставаться в общей консоли рядом с `con_pin`. В виде `log` декодированный байт MUST печататься строкой `t=<ns> uart <имя> <байт>`. Blinky этот канал MUST NOT вызывать и экран строки набора MUST NOT открывать. Строки `pin` MUST печататься по-прежнему: `t=<ns> pin led <значение>` только при смене уровня.

#### Scenario: Байт ещё не подключён
- **WHEN** идёт эмуляция blinky
- **THEN** в консоли нет строк `uart`

#### Scenario: Журнал led на месте
- **WHEN** тест задаёт `LED_BIT` 4 и `FSOC_EMU_EDGES=2` с `FSOC_EMU_FAST=1`
- **THEN** в журнале есть строки `pin led 0` и `pin led 1`
