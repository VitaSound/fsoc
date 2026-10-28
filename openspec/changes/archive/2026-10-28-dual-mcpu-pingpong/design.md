# Design: dual-mcpu-pingpong

## Context

MCPU — 8-битное микроядро (64 байта, NOR/ADD/STA/JCC), уже есть fasm и `standalone_mcpu`. Профиля Forth нет. Это сознательный выбор для демо MPSoC без консоли fsys.

## Approach

```text
cpu0 (ping.hex) ──┐
                  ├── mailbox @ 62 ── mbox byte → harness pin ping/pong
cpu1 (pong.hex) ──┘
```

- У каждого ядра своя RAM 64 байта (`$readmemh` из `cpu0.hex` / `cpu1.hex`).
- Адрес 62 у обоих отображается на один `mbox_byte`.
- Протокол: A пишет `1`, ждёт `2`, пишет `0`; B ждёт `1`, пишет `2`, ждёт `0`.
- Память гонит шину, пока `we` высок (удержание данных через posedge; Verilator игнорирует `#5` из upstream RamChip). Запись — по `negedge we`.

## Task wiring

- `s" dual-mcpu" task:` + `emulation` → harness `dual_mcpu_main.cpp`.
- Нет `sys:` / `cpu:` профиля Forth.

## Out of scope

- Два j1a, гетерогенные ISA, синтез dual на плате.
