# Design: drop-swapforth

## Decision

Один `sys:` id для образов с консолью: `fsys`. Пустое поле — ошибка, как у AVR/bcpu. Каталог `swapforth/` удаляется из репозитория (атрибуция — строка в CHANGELOG).

## Code

- [`fsoc/tasks/soc.4th`](fsoc/tasks/soc.4th): убрать `soc-swapforth`, cross/feed/SwapForth helpers; оставить flatten для `include` в `lamp.fs` (только относительный путь); `soc-sys-id` при пустом поле печатает `needs fsys` и abort.
- Манифесты j1 → `s" fsys" sys:`.
- Тесты ожидают `image tool: fsys` и пути `fsys/kernel/…`.

## Out of scope

- `cgf-dispatch-pinmap` и рефакторинг modules/LSP.
- Исторические упоминания SwapForth в `openspec/changes/archive/`.
