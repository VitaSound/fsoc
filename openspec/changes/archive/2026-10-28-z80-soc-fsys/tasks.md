# Tasks

## 1. OpenSpec и top

- [x] 1.1 Дельта forth-cross / fsys: z80 + fsys пишет byte hex; пустой sys: останавливается
- [x] 1.2 `cpu/z80/top_soc.v` (16 КБ, UART queue, LED/IO)
- [x] 1.3 `cg-z80.4th` `z80-soc`; ветка в `cg-f`

## 2. Ядро и cross

- [x] 2.1 `fsys/kernel/z80/kernel.4th` — создан с консолью на словах fasm, accept, words, colon, и т.д. (1162 строки)
- [x] 2.2 `fsys/host/z80-cross.4th`, `extra-min`, `firmware/z80_blink.fs` — созданы cross-compiler, extra-min слой и прошивка blink

## 3. Проекты и con_core

- [x] 3.1 `soc_z80`, `soc_z80_blink` — проекты созданы с target.4th и firmware.hex
- [x] 3.2 `con_session` / `con_core`, JSON, теги `con_words.py` — z80-fsys-manifest добавлен в con_session.4th, con_core_test.4th гоняет сеанс z80

## 4. Сдача

- [x] 4.1 `z80_test` + con_core; три сеанса эмуляции; docs / flint-exclude
  - `z80_test ok`; `con_core_test ok` (z80: core / words / behavior)
  - Session 1 (blinky_z80, pin, EDGES=4): `pin led 0` и `pin led 1` каждый ≥2
  - Session 2 (soc_z80_blink, pin): оба уровня ≥2; term: `blink on` / `blink off`
  - Session 3 (soc_z80, без UART_GAP): `words`, `1 2 + .` → `3 ok`, `: T 9 . ;` / `T` → `9`
  - Kernel fixes: `hl TIBA ldw`, `zdrop` при depth=1, `header` name copy через `djnz`
  - flint-exclude уже в `package.4th` для fsys/kernel/z80/, fasm/z80/, host/z80-cross, fsys/z80/
  - OpenSpec delta: `openspec/changes/z80-soc-fsys/`
