# Spec Delta

## REMOVED Requirements

### Requirement: CSR пишется в каталог проекта
**Reason**: Карта `ctrl`, `uart`, `gpio`, `timer` с адресами 0, 4, 8… не соответствует ни одному устройству на шине `io` J1; `csr.4th` описывал несуществующее.
**Migration**: Адреса устройств — в `csr.fs`, `iomap.vh` и `csr.json`, которые пишет карта `iomap` (см. спеку `iomap`).

## MODIFIED Requirements

### Requirement: Запуск как у blinky
Идентичность проекта MUST читаться из `target.4th`: задача `soc`, таргет `emulation`, плата не задана. `fsoc --build` MUST породить `top.v`, `firmware.hex`, `csr.fs`, `iomap.vh`, `csr.json` и `sim.sh`, затем запустить просмотр. На этом проекте `--load` MUST игнорироваться без ошибки.

#### Scenario: Сборка из каталога проекта
- **WHEN** в `projects/soc_emul` выполняется `fsoc --build`
- **THEN** появляются `top.v`, `firmware.hex`, `sim.sh`, `csr.fs`, `iomap.vh` и `csr.json`, Verilator компилируется и просмотр идёт до Ctrl+C

## ADDED Requirements

### Requirement: Прошивка берёт адреса из карты
Файл прошивки проекта (`firmware/lamp.fs` и последующие) MUST начинаться с `include csr.fs` и MUST обращаться к шине через константы `IO-<ИМЯ>`. Литералы адресов `h# 400`, `h# 800`, `h# 1000`, `h# 2000` MUST NOT стоять в прошивке проекта. Билдер MUST подать `csr.fs` в образ до прошивки проекта.

#### Scenario: Лампа через константы
- **WHEN** в `projects/soc_blink` выполняется `fsoc --build` с `FSOC_EMU_FAST=1`, `FSOC_EMU_CON=term`, `FSOC_EMU_CYCLES=200000`
- **THEN** вывод содержит `lamp on` и `lamp off`, `firmware/lamp.fs` содержит `IO-LED` и `IO-TIMER`, а `rg "h# *(400|800|1000|2000)" firmware/` пусто
