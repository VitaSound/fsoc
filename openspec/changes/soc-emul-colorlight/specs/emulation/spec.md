# Spec Delta

## ADDED Requirements

### Requirement: Частота sim.sh с платы
Когда таргет оставляет `sim.sh` и плата загружена, `sim.sh` MUST записать `CLK_HZ`, равный частоте тактового ресурса. Без платы `sim.sh` MUST записать `CLK_HZ=50000000`. Делитель бита UART MUST считаться из этой строки и `BAUD`. Промежуточный `sim.sh` шага feed на таргете платы MUST оставаться на 50 МГц, чтобы совпасть с топом feed, и MUST быть удалён до конца этой сборки.

#### Scenario: Colorlight 25 МГц
- **WHEN** в `projects/soc_emul_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** `sim.sh` содержит `CLK_HZ=25000000` и `BAUD=115200`, а журнал содержит `3` и ` ok`

#### Scenario: Эмуляция без платы
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** `sim.sh` содержит `CLK_HZ=50000000`
