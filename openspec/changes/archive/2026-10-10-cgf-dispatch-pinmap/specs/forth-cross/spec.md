# Spec Delta

## MODIFIED Requirements

### Requirement: Сборка MCU ветвится по CG
Задача `soc` MUST выбирать излучатель по полю CG профиля. `fsoc/tasks/soc.4th` MUST NOT ветвить сборку по литералу id MCU (`avr`, `stm8`, `z80`, `j1abs`, `bcpu` и любому следующему). Ветвление по CG MUST жить в уже зарегистрированном излучателе (`cg-f.4th` для CG=F, путь CG=I для J1). Внутри CG=F выбор профиля MUST идти через xt-поля `cpu%` (`cpu.cg-soc` для soc/fsys, `cpu.cg-blinky` для baremetal blinky), установленные при регистрации профиля. `cg-f.4th` и слово `blinky-mcu-f` MUST NOT содержать цепочку `s" <id>" compare` по id MCU. Новый CG=F с `fsys` MUST писать образ тем же излучателем CG=F, вызывая xt профиля. Формат образа (Intel HEX / слово-hex / byte-hex) MUST оставаться как у текущего профиля.

#### Scenario: soc.4th не знает MCU-профили
- **WHEN** читается `fsoc/tasks/soc.4th`
- **THEN** в нём нет литерала `avr`, нет литерала `stm8`, нет литерала `j1abs` и нет литерала `bcpu` как ветвления сборки образа

#### Scenario: cg-f без id-compare
- **WHEN** читаются `fsoc/tasks/cg-f.4th` и определение `blinky-mcu-f`
- **THEN** в них нет цепочки `s" avr" compare` / `s" bcpu" compare` / `s" cd16" compare` / `s" msl16" compare` / `s" z80" compare` для выбора излучателя

#### Scenario: Новый CG=F регистрирует xt
- **WHEN** в `cpu.4th` регистрируется профиль с CG=F
- **THEN** у него ненулевые `cpu.cg-soc` и `cpu.cg-blinky`, и `fsoc --build` для `s" fsys" sys:` вызывает `cpu.cg-soc`

## ADDED Requirements

### Requirement: Профиль CG=F без xt останавливается
Профиль с CG=F MUST иметь установленные `cpu.cg-soc` и `cpu.cg-blinky` до первой сборки. Нулевой xt MUST останавливать сборку с текстом, содержащим id профиля и `no cg-soc` или `no cg-blinky`, и MUST NOT писать `firmware.hex`.

#### Scenario: CG=F без cg-soc
- **WHEN** профиль с CG=F имеет `cpu.cg-soc` равный 0 и выполняется `fsoc --build` задачи `soc` с `s" fsys" sys:`
- **THEN** сборка останавливается до записи `firmware.hex` с текстом, содержащим `no cg-soc`
