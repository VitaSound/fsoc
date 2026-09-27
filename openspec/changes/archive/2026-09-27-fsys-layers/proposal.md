# Proposal

## Why

SwapForth — система на кристалле, а не часть комплекта Verilog. Сейчас задача `soc` сама вызывает её кросс и ищет файлы в `cpu/j1/swapforth/`. Рядом нужен второй инструмент, fsys, со слоями fasm, kernel и common, чтобы на том же чипе и UART получить консоль: `words` и сложение. Выбор инструмента — поле манифеста, не имя платы и не `target:`.

## What Changes

- Каталог `cpu/j1/swapforth/` переезжает целиком в `swapforth/` (`j1a/`, `j1b/`, `common/`, лицензия). Слои монолита не раскладываются по деревьям fsys.
- Поле манифеста `sys:` рядом с `cpu:`. Пустое значение — `swapforth`, поэтому текущие `target.4th` не меняются. Неизвестный id останавливает сборку до кросса. `s" fsys" sys:` не читает файлы SwapForth и не подставляет его hex.
- Задача `soc` не знает, какой Форт заполняет `firmware.hex`. Она вызывает один шаг выбранного `sys:`. У SwapForth это кросс ядра и подача по UART. У fsys голый `[asm]` может записать hex без подачи.
- Экосистема fsys: `fsys/fasm/j1a` и `fsys/fasm/j1b` (слова с запятой, метки, `[asm]`/`[endasm]`), затем `fsys/kernel/j1a` и `fsys/kernel/j1b`, затем один `fsys/common/` на оба процессора. Четвёртого слоя нет. `firmware/lamp.fs` остаётся приложением снаружи fsys.
- Поведение fsys на сессии то же, что нужно для примера SwapForth: после kernel строка `words` печатает словарь, `1 2 + .` печатает `3` и ` ok`. Common дописывает `variable`, деление и строки. Полный список ANS CORE из спецификации `soc` для fsys не требуется и остаётся требованием только к `sys:` равному `swapforth`.
- Каждый слой fsys закрыт тестами `fcov` не ниже 90%, порог считается отдельно по `fasm/j1a`, `fasm/j1b`, `kernel/j1a`, `kernel/j1b` и `common`.
- `kit.cross$` уходит из комплекта: железо не называет прошивку.

## Capabilities

### New Capabilities

- `fsys`: слои fasm, kernel и common, голый `[asm]`, консоль `words` и сложение, порог покрытия 90%.

### Modified Capabilities

- `forth-cross`: путь образа SwapForth становится `swapforth/<id>/`; поле `sys:` выбирает инструмент; пустое `sys:` — `swapforth`; комплект не хранит имя кросса.
- `soc`: требования «образ — SwapForth» и полный словарь ANS CORE действуют при пустом `sys:` и при `swapforth`. При `fsys` образ берётся из fsys и не совпадает с hex SwapForth. Шаг feed остаётся шагом SwapForth, не единственным способом заполнить `firmware.hex`.
- `builder`: в список слов манифеста входит `sys:`. Пустое поле не ошибка. Неизвестный id останавливает сборку.

## Impact

- `fsoc/project.4th` — слово `sys:`. `fsoc/tasks/soc.4th` перестаёт вызывать `soc-cross` и `soc-feed` напрямую. `fsoc/kit.4th` и `cpu/j1/j1a/kit.4th`, `cpu/j1/j1b/kit.4th` больше не называют каталог прошивки.
- Новые деревья `swapforth/` и `fsys/`. Каталог `cpu/j1/swapforth/` удаляется после переноса. Verilog комплекта, `uart.v` и `iomap.vh` остаются в `cpu/j1/`.
- Тесты `tests/cpu_test.4th`, `tests/soc_test.4th`, `tests/soc_blink_test.4th`, `AGENTS.md`, `CHANGELOG.md`. `projects/soc_emul/target.4th` остаётся консолью j1a без `cpu: j1b`.
- Спецификация `soc` больше не описывает всякий образ SoC как SwapForth J1a с полным ANS CORE: это поведение инструмента `swapforth`.
