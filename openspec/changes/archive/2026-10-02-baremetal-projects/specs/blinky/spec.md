# Spec Delta

## ADDED Requirements

### Requirement: HDL-blinky собирается из baremetal
Эмуляция, Quartus и Yosys для задачи `blinky` MUST читать манифест из `projects/baremetal/`.

#### Scenario: Три проекта под baremetal
- **WHEN** собраны `projects/baremetal/blinky_emul`, `projects/baremetal/blinky_terasic_de0nano` и `projects/baremetal/blinky_colorlight_5a_75e_v6_0`
- **THEN** в каждом есть свой `top.v` и копия `blinky.v`, а источник листа по-прежнему `rtl/blinky.v`
