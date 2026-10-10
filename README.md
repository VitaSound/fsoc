# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.9.0-green.svg)](https://github.com/VitaSound/fsoc)

Русская версия. English: [README-eng.md](README-eng.md).

Сборщик SoC на Форте: **платы**, **тулчейны Quartus/Yosys/Verilator**, **iomap**, **прошивка**. Аналог LiteX `build` + `soc` на Gforth. Модули Verilog — из [fhdlgen](https://github.com/VitaSound/fhdlgen) и [hdl-modules](https://github.com/VitaSound/hdl-modules). Пресс-релиз: [doc/PRESS-RELEASE-ru.md](doc/PRESS-RELEASE-ru.md).

На одном холсте — soft-CPU на ПЛИС и MCU (ATmega8), плюс демо **двух микроядер** с обменом ping/pong. «Два ядра J1» в пресс-релизе — это профили **j1a и j1b**, не dual-core; MPSoC — [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).

## Что нужно в первый час

- Gforth, `fmix packages.get`, `FSOC_HOME` и `PATH` (см. [feco shell-setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md))
- Для пути ПЛИС: **Verilator**
- Для пути MCU: сборка HEX всегда; интерактив — **simavr** + `libsimavr-dev` (иначе консоль пропускается)
- **Не** нужны в первый час: Quartus, Yosys/nextpnr, Proteus, fhdlgen

Полный прогон: `fmix test`. Развёрнутый гайд (платы, fit, все CPU): [doc/guide-detail-ru.md](doc/guide-detail-ru.md).

## День 1

```bash
git clone git@github.com:VitaSound/fsoc.git
cd fsoc && fmix packages.get
export FSOC_HOME="$PWD"
export PATH="$FSOC_HOME/bin:$PATH"
fsoc version
```

Выберите путь:

### ПЛИС / soft-CPU (Verilator)

```bash
cd projects/baremetal/blinky_emul && fsoc --build
# t=<ns> pin led 0 / pin led 1

cd ../soc_emul
FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .' fsoc --build
# 3 и ok
```

### MCU (ATmega8)

```bash
cd projects/baremetal/blinky_atmega && fsoc --build
# Hardware atmega8(avr), firmware.hex

cd ../../soc_atmega8 && fsoc --build
# без simavr — только HEX; с пакетами:
# sudo apt install simavr libsimavr-dev gcc
~/fsoc/tools/avr-con ./firmware.hex '1 2 + .'
```

### Два микроядра (MPSoC)

```bash
cd projects/baremetal/dual_mcpu_emul
FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 fsoc --build
# pin ping 1 и pin pong 1 (каждый ≥ 2 раз)
```

Подробности: [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).

Термины: [doc/GLOSSARY.md](doc/GLOSSARY.md). Слои репозитория: [doc/MAP.md](doc/MAP.md). Профили CPU / FMAP: [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).  
Человек: [CONTRIBUTING.md](CONTRIBUTING.md). Агент: [AGENTS.md](AGENTS.md) и `.cursor/rules/`.

## Установка (кратко)

WavePeek опционален (`fmix test` его не вызывает). Навык: [`.cursor/skills/wavepeek`](.cursor/skills/wavepeek).

`fmix test` включает сетку консоли fsys [`tests/con_core_test.4th`](tests/con_core_test.4th). Один файл:

```bash
export FSOC_HOME="$HOME/fsoc"
cd tests && gforth con_core_test.4th
```

## Как устроена сборка

В git в каталоге проекта — только `target.4th`. `fsoc --build` пишет остальное на месте. Задача и плата — в манифесте, не в CLI.

```forth
s" blinky" task:            \ или soc / dual-mcpu / standalone
s" emulation" target:       \ emulation | quartus | yosys
s" fsys" sys:               \ для soc обязательно
s" lamp" s" 1" option:
```

| Таргет | `run` |
|--------|-------|
| `emulation` | Verilator (`sim.sh`) |
| `quartus` | файлы проекта; `--load` → `load.sh` |
| `yosys` | `build.sh` (nextpnr) |

Детали мигалки, SoC, Colorlight, DE0-Nano, AVR, bcpu, j1abs, standalone-fit — в [doc/guide-detail-ru.md](doc/guide-detail-ru.md).

## Платы

| Плата | Микросхема | Заметки |
|-------|------------|---------|
| `terasic_de0nano` | EP4CE22F17C6 | Quartus, USB-UART |
| `colorlight_5a_75e_v6_0` | LFE5U-25F | Yosys/nextpnr, 25 МГц |
| `lfe5u25f_cabga256` | LFE5U-25F | карта шаров для standalone |
| `ep2c5_mini` | EP2C5T144C8 | Quartus |

## Новый CPU

Новая **ISA** — новый id `cpu:` и слои fsys (см. [`.cursor/rules/fsoc-cpu-target.mdc`](.cursor/rules/fsoc-cpu-target.mdc)). Новая микросхема той же ISA — файл части под fasm. Консоль fsys должна войти в `tests/con_core_test.4th`. Оси FMAP: [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).

## Связанное

- [MIT ADR-0003](https://github.com/VitaSound/MIT) — сборщик SoC на Форте
- [feco](https://github.com/VitaSound/feco) · [fhdlgen](https://github.com/VitaSound/fhdlgen) · [frules](https://github.com/VitaSound/frules)
