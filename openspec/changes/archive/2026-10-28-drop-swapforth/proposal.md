# Proposal: drop-swapforth

## Why

Два инструмента образа (SwapForth и fsys) путают людей и дублируют приёмку. fsys уже покрывает j1a/j1b и все MCU-консоли. SwapForth — лишний путь.

## What Changes

- Удалить каталог `swapforth/` и регистрацию `sys: swapforth`.
- Пустое `sys:` на задаче `soc` MUST останавливать сборку (`needs fsys`).
- Единственный образный путь: `s" fsys" sys:`.
- Мигрировать `soc_emul`, `soc_blink`, `soc_emul_colorlight_*`, `soc_terasic_de0nano` на fsys.
- Удалить JSON `swapforth-j1a` / `swapforth-j1b` и ветки в `build.py`.
- Удалить временный `ANALYSIS.md`.
- Обновить спеки, README, AGENTS, PRESS.

## Impact

- **BREAKING** для манифестов с пустым `sys:` или `s" swapforth" sys:`.
- Спеки: `forth-cross`, `fsys`, `soc`, `builder`, `emulation`.
