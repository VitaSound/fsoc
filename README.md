# fsoc

[![License](https://img.shields.io/badge/License-COPL-red.svg)](LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.9.0-green.svg)](https://github.com/VitaSound/fsoc)

Русская версия. English: [README-eng.md](README-eng.md).

Сборщик SoC на Форте: **платы**, **тулчейны Quartus/Yosys/Verilator**, **iomap**, **прошивка**. Аналог LiteX `build` + `soc` на Gforth. Модули Verilog — из [fhdlgen](https://github.com/VitaSound/fhdlgen) и [hdl-modules](https://github.com/VitaSound/hdl-modules). Пресс-релиз: [doc/PRESS-RELEASE-ru.md](doc/PRESS-RELEASE-ru.md).

За первый час соберёте **мигалку** в Verilator (`pin led 0` / `1`) и **консоль Forth**, которая ответит `3` и `ok`. Платы, другие CPU и fit — после Day-1. «Два ядра J1» в пресс-релизе — это профили **j1a и j1b**, не dual-core; два микроядра на шине — [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).

## Что нужно в первый час

- Gforth, `fmix packages.get`, `FSOC_HOME` и `PATH` (см. [feco shell-setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md))
- **Verilator** (канон ниже)
- **Не** нужны в первый час: Quartus, Yosys/nextpnr, Proteus, fhdlgen, simavr

Полный прогон: `fmix test`. Пять терминов Day-1: [doc/GLOSSARY.md](doc/GLOSSARY.md). После Day-1 (платы, fit, остальные CPU): [doc/guide-detail-ru.md](doc/guide-detail-ru.md) — в первый час не открывайте.

## День 1 — начните здесь (ПЛИС / Verilator)

```bash
git clone git@github.com:VitaSound/fsoc.git
cd fsoc && fmix packages.get
export FSOC_HOME="$PWD"
export PATH="$FSOC_HOME/bin:$PATH"
fsoc version
```

### 1. Мигалка (без Forth)

```bash
cd projects/baremetal/blinky_emul && fsoc --build
```

В логе периодически:

```text
t=<ns> pin led 0
t=<ns> pin led 1
```

Остановка — Ctrl+C.

### 2. Консоль Forth (`3` и `ok`)

```bash
cd projects/soc/soc_emul
FSOC_EMU_FAST=1 FSOC_EMU_UART_IN='1 2 + .' fsoc --build
```

В логе:

```text
3  ok
```

В git в каждом `projects/*` лежит только `target.4th`; `fsoc --build` пишет остальное на месте.

## Три режима

| Режим | В `target.4th` | Что получите | Пример |
|-------|----------------|--------------|--------|
| Мигалка | `blinky` | пины LED, **без** консоли Forth | `baremetal/blinky_emul` |
| Консоль SoC | `soc` + `sys: fsys` | UART / `ok`, слова `+` `.` `:` | `soc/soc_emul` |
| Два микроядра | `dual-mcpu` | `pin ping` / `pin pong`, **не** fsys | `baremetal/dual_mcpu_emul` |

Позже (не Day-1): `soc/soc_atmega8` (MCU HEX), `soc/soc_blink` (лампа на soft-CPU).

## Ещё пути

### MCU (ATmega8)

```bash
cd projects/baremetal/blinky_atmega && fsoc --build
# Hardware atmega8(avr), firmware.hex

cd ../../soc/soc_atmega8 && fsoc --build
# HEX всегда; интерактив — simavr + libsimavr-dev:
# ~/fsoc/tools/avr-con ./firmware.hex '1 2 + .'
```

### Два микроядра (MPSoC)

```bash
cd projects/baremetal/dual_mcpu_emul
FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1 fsoc --build
# pin ping 1 и pin pong 1 (каждый ≥ 2 раз)
```

Подробности: [doc/mcpu-pingpong.md](doc/mcpu-pingpong.md).

Слои репозитория: [doc/MAP.md](doc/MAP.md). Профили CPU: [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).  
Человек: [CONTRIBUTING.md](CONTRIBUTING.md). Агент: [AGENTS.md](AGENTS.md) и `.cursor/rules/`.

## Как устроена сборка

Каталог проекта + `target.4th` → `fsoc --build` → артефакты рядом (`sim.sh`, HEX, …). В git остаётся только манифест. Задача и плата — в манифесте, не в CLI.

Мигалка (без `sys:`):

```forth
s" blinky" task:
s" emulation" target:
```

Консоль SoC — обязательно `s" fsys" sys:`, иначе сборка останавливается (`needs fsys`):

```forth
s" soc" task:
s" emulation" target:
s" fsys" sys:
s" lamp" s" 1" option:   \ опционально: цикл лампы вместо приглашения
```

| Таргет | `run` |
|--------|-------|
| `emulation` | Verilator (`sim.sh`) |
| `quartus` | файлы проекта; `--load` → `load.sh` |
| `yosys` | `build.sh` (nextpnr) |

Платы и сценарии fit — в [doc/guide-detail-ru.md](doc/guide-detail-ru.md) (после Day-1).

## Установка (кратко)

WavePeek опционален (`fmix test` его не вызывает). Навык: [`.cursor/skills/wavepeek`](.cursor/skills/wavepeek).

`fmix test` включает сетку консоли fsys [`tests/con_core_test.4th`](tests/con_core_test.4th). Один файл:

```bash
export FSOC_HOME="$HOME/fsoc"
cd tests && gforth con_core_test.4th
```

## Новый CPU

Новая **ISA** — новый id `cpu:` и слои fsys. Новая микросхема той же ISA — файл части под fasm. Консоль fsys должна войти в `tests/con_core_test.4th`. Инструкция: [doc/add-cpu.md](doc/add-cpu.md). Оси FMAP: [doc/FMAP-INDEX.md](doc/FMAP-INDEX.md).

## Связанное

- [MIT ADR-0003](https://github.com/VitaSound/MIT) — сборщик SoC на Форте
- [feco](https://github.com/VitaSound/feco) · [fhdlgen](https://github.com/VitaSound/fhdlgen) · [frules](https://github.com/VitaSound/frules)
