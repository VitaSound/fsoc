# Spec Delta

## ADDED Requirements

### Requirement: Задача SoC на таргете платы
Задача `soc` MUST собираться на любом зарегистрированном таргете без ветвления по имени таргета: при заданной плате задача MUST загрузить её, запросить `clk50`, `user_led`, `serial` и заполнить карту пинов; таргет `quartus` MUST записать из неё файлы проекта, таргет `emulation` MUST её игнорировать.

#### Scenario: Один и тот же дизайн на двух таргетах
- **WHEN** `projects/soc_emul` и `projects/soc_vitasound_ep4ce10` называют `designs/soc_console.4th` и выполняется `fsoc --build` в каждом
- **THEN** первый каталог содержит `sim.sh` и не содержит `.qsf`, второй содержит `soc.qsf` и не содержит `sim.sh`, а `fsoc/tasks/soc.4th` не содержит литералов `quartus` и `emulation`
