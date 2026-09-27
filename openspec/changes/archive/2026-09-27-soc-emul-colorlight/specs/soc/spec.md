# Spec Delta

## ADDED Requirements

### Requirement: Консоль на эмуляции Colorlight
Проект `projects/soc_emul_colorlight_5a_75e_v6_0` MUST собираться задачей `soc`, таргетом `emulation`, платой `colorlight_5a_75e_v6_0` и дизайном `designs/soc_console.4th`. Топ MUST получить `CLK_HZ` тактового ресурса платы и `BAUD` 115200 и MUST сохранить порты `uart_rx`, `uart_tx`, `rst` и `dump`. Параметры `BOARD`, `NO_UART`, `LED_LOW` и `TIMER_DIV` MUST NOT попадать в этот топ. Сеанс `1 2 + .` MUST ответить `3` и ` ok`.

#### Scenario: Сеанс на 25 МГц
- **WHEN** в `projects/soc_emul_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** код возврата 0, журнал содержит `3` и ` ok`, `top.v` содержит `CLK_HZ(25000000)`, `BAUD(115200)` и `input wire uart_rx`, `sim.sh` содержит `CLK_HZ=25000000`, а `soc.lpf` и `soc.qsf` отсутствуют
