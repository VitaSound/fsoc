# Spec Delta

## MODIFIED Requirements

### Requirement: Задача SoC на таргете платы
Задача `soc` MUST собираться на зарегистрированном таргете без сравнения имени таргета со строками `quartus`, `emulation` или `yosys`. При заданной плате задача MUST загрузить её, запросить единственный тактовый ресурс (`plat-clock`) и `user_led`, и MUST запросить `serial` только когда `s" serial" 0 io-find` его находит. Таргет `quartus` MUST записать `.qsf` из карты пинов. Таргет `emulation` MUST карту пинов игнорировать, MUST оставить `sim.sh` и MUST NOT писать `.qsf` или `.lpf`. Таргет `yosys` MUST записать `.lpf` из той же карты.

#### Scenario: Один и тот же дизайн на двух таргетах
- **WHEN** `projects/soc_emul` и `projects/soc_vitasound_ep4ce10` называют `designs/soc_console.4th` и выполняется `fsoc --build` в каждом
- **THEN** первый каталог содержит `sim.sh` и не содержит `.qsf`, второй содержит `soc.qsf` и не содержит `sim.sh`

#### Scenario: Лампа на Yosys
- **WHEN** в `projects/soc_blink_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_SYNTH_SKIP=1`
- **THEN** каталог содержит `soc.lpf` и не содержит `sim.sh` и `soc.qsf`

#### Scenario: Консоль на эмуляции с платой
- **WHEN** в `projects/soc_emul_colorlight_5a_75e_v6_0` выполняется `fsoc --build` с `FSOC_EMU_FAST=1` и `FSOC_EMU_UART_IN`, равным `1 2 + .`
- **THEN** каталог содержит `sim.sh` и не содержит `soc.qsf` и `soc.lpf`, а `fsoc/tasks/soc.4th` не сравнивает имя таргета со строками `quartus`, `emulation` и `yosys`
