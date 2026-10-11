# AT89C52 в Proteus (hard 8051)

Хост пишет **Intel HEX**. Proteus его только открывает. Soft R8051 (Verilator) — [8051-soft.md](8051-soft.md).

Сборка:

```bash
cd projects/baremetal/blinky_8051 && fsoc --build
cd projects/soc/soc_at89c52 && fsoc --build
cd projects/soc/soc_at89c52_blink && fsoc --build
```

`target: proteus` и неуказанный `body` → hard. Явно: `s" body" s" hard" option:`. Log: `at89c52(8051)`, `image tool: fsys` или `fasm`, `firmware.hex: N bytes of 8192`, без `Vtop_feed`.

## Схема ISIS

- Корпус **AT89C52**. Clock Frequency — 11.0592 МГц (или ваша XTAL).
- Светодиод с резистором от `P1.0` к земле (активный высокий в blink).
- Virtual Terminal, 9600 бод. TX терминала на RXD (`P3.0`), RX терминала на TXD (`P3.1`). Enter — CR; консоль принимает CR и LF.
- Program File — свежий `firmware.hex` после `fsoc --build`.

`soc_at89c52` — Forth-консоль (`sys: fsys`). `soc_at89c52_blink` — `blink` option + `firmware/8051_blink.fs`. `blinky_8051` — baremetal fasm, без kernel.

## Опционально без Proteus: ucsim

На машине с пакетом `sdcc-ucsim` есть `s51` (бинаря `ucsim-51` нет). Обёртка:

```bash
cd projects/soc/soc_at89c52 && fsoc --build
"$FSOC_HOME/tools/8051-con" ./firmware.hex
"$FSOC_HOME/tools/8051-con" ./firmware.hex '1 2 + .'
```

Приёмка консоли soft — Verilator (`con_core`). ucsim не заменяет Proteus для hard pin/UART timing.
