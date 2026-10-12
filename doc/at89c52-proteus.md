# AT89C52 в Proteus (hard 8051)

Хост пишет **Intel HEX**. Proteus его только открывает. Soft R8051 (Verilator) — [8051-soft.md](8051-soft.md).

## Два режима hard

| Режим | Проект | Схема |
|-------|--------|--------|
| Только лампа | `projects/baremetal/blinky_8051` | AT89C52 + LED на `P1.0` |
| Forth / blink + UART | `soc_8051_blink` / `soc_at89c52*` (`proteus`) | AT89C52 + LED + Virtual Terminal |

Hard fsys кладёт VM (стек, TIB, переменные) в **on-chip IRAM** — внешняя 6264 для blink/консоли **не нужна**. Код в internal flash (MOVC). Soft по-прежнему использует XRAM `$2000+`.

## Лампа (без XRAM) — протестировано

```bash
cd projects/baremetal/blinky_8051 && fsoc --build
```

- AT89C52, Clock **11.0592 МГц**, LED на `P1.0`, свежий Program File.
- Virtual Terminal не нужен.

## Консоль / soc blink (IRAM VM)

```bash
cd projects/soc/soc_8051_blink && fsoc --build
# log: vm: iram · open firmware.hex in Proteus
```

Схема ISIS (внешняя SRAM не обязательна):

| Пин | Куда | Зачем |
|-----|------|--------|
| **EA (31)** | **VCC** | Внутренний ROM. **Плавающий EA** → через секунды уход во внешний code bus и «зависание» без `*+IB` |
| **RST (9)** | GND (или RC на GND) | Иначе ложные сбросы |
| Clock | **11.0592 МГц** в свойствах MCU | Иначе мусор/тишина на 9600 |
| P1.0 | LED (+ резистор на GND) | `p1!` |
| P3.1/TXD | VT **RXD** | Вывод |
| P3.0/RXD | VT **TXD** (если нужен ввод) | |
| Program File | свежий Intel HEX | после каждого `fsoc --build` |

- MCU: **AT89C52** / 80C52, ROM **≥ 8K**. На 4K (`80C51`) blink CFA за `$0FFF` → сброс.
- Внешняя 6264 для hard IRAM VM **не нужна**.

**Работает (2026-10-11):** один раз `*+IB`, затем строки `+` / `-` и мигание LED. Образ IRAM VM, Intel call-stack, STC `exit`.

Если снова «замерло» через несколько секунд: **EA→VCC**, и свежий HEX с data stack `$FE` + asm `dly` (старый `$7E` сталкивался с SP при глубоких LCALL → выход в `KEY` и тишина).

Soft-консоль без Proteus:

```bash
cd projects/soc/soc_8051
FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_UART_IN=$'1 2 + .\nwords\n' fsoc --build
```

## Опционально: ucsim

```bash
cd projects/soc/soc_8051 && fsoc --build
"$FSOC_HOME/tools/8051-con" ./firmware.hex '1 2 + .'
```

Приёмка soft — Verilator (`con_core`). ucsim не заменяет Proteus для pin/UART timing.
