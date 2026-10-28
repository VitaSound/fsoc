# Новый CPU / MCU в fsoc

Как добавить целевую платформу: новый id `cpu:` и слои fsys. Не blink HEX «вместо ядра».

English: [add-cpu-eng.md](add-cpu-eng.md). Оси FMAP: [FMAP-INDEX.md](FMAP-INDEX.md). Требования: [`openspec/specs/forth-cross/spec.md`](../openspec/specs/forth-cross/spec.md), [`openspec/specs/fsys/spec.md`](../openspec/specs/fsys/spec.md).

## Id vs микросхема

| Случай | Что делать |
|--------|------------|
| Новая **ISA** | Новый id в [`fsoc/cpu.4th`](../fsoc/cpu.4th) (`cpu-new`: класс FMAP, MM, EX-C, CG, BM) и полный набор слоёв ниже |
| Новый **корпус** той же ISA (`atmega328p` рядом с `atmega8`) | Только файл части под `fsys/fasm/<id>/`. Поле манифеста `model:` — id этого файла; пустой `model:` берёт `cpu-ref` |

Эталоны: `avr` (class 1, MM=D, EX-C=S, CG=F), `j1a` (class 0, MM=V, EX-C=V, CG=I), `bcpu` (class 0, MM=U, EX-C=B, CG=F).

## Слои (тот же canvas, что у j1a / j1b / avr)

| Слой | Путь | Роль |
|------|------|------|
| Ассемблер | `fsys/fasm/<id>/` | Только comma-слова. Без словаря, `quit`, app-цикла |
| Ядро | `fsys/kernel/<id>/kernel.4th` | Forth-**консоль** на этом fasm: стеки, `@` `!`, UART `KEY`/`EMIT`, `:` `;`, `quit`, `words`, ` ok`. Не blink/lamp |
| Хост-кросс | `fsys/host/<id>-cross.4th` | Хост собирает образ. Не подставлять ALU-опкоды J1 под MCU-колон |
| Extra / release | `fsys/<id>/extra.4th`, `release.4th` | Слова чипа поверх ядра. Не ассемблер |
| App | `firmware/<name>.fs` | `'BOOT` / I/O. Опция манифеста (`lamp`, `blink`) |

`fsys/common` — **один** текст для id, чей кросс его читает. Если не может — кросс даёт те же **имена** (`if` `then` `variable` …); не копировать `common.4th` на каждый CPU.

## Сборка

- Манифест `cpu:` выбирает профиль; **CG** выбирает излучатель. `target:` — как запускать (emulation, quartus, proteus).
- Не добавлять литерал нового id в `fsoc/tasks/soc.4th`. Ветвление — в уже зарегистрированном файле CG (`cg-f.4th` для CG=F, `soc-cg-i` для CG=I).
- Пустое `sys:` у задачи `soc` **останавливает** сборку (`needs fsys`). Образ консоли обязан задать `s" fsys" sys:`. Голая мигалка — задача `blinky` плюс `cpu:`; она `sys:` не читает. fasm в журнале — ассемблер, не имя задачи.
- **CG=I** (class 0 J1): Verilog-комплект под `cpu/j1/<id>/`, образ через `soc-fsys`.
- **CG=F** (class 1/2 MCU, HEX): хост fasm + слои fsys, без `Vtop_feed`. Журнал как у J1: `Hardware` печатает `atmega8(avr)`, `Software` — `firmware.hex: <used> bytes of <flash>`.
- **CG=E** (сейчас stm8): без hex; внешнее ядро (например stm8ef). Не изобретать fasm-kernel, пока профиль этого не меняет.

## Не делать

- Ядро как «вся программа» (нет `sbi DDRB` в `kernel.4th`).
- Исходники приложения в `fsys/fasm/<id>/`.
- Идиомы Gforth-хоста в целевом ядре без решения по FMAP/EX-C.
- AmForth / FlashForth как ядро fsoc, пока в манифесте явно не назван другой `sys:`.
- Заглушку списка слов, когда исходника образа нет — остановиться и спросить.
- Новый id консоли fsys без строки в `tests/con_core_test.4th`.

## Сетка консоли (обязательна для нового fsys id)

Новая ISA с Forth-**консолью** обязана войти в общую REPL-сетку. Файл части микросхемы того же id — **нет**.

1. То же стирание в `accept`, что у j1a/j1b/avr: байты 8 и 127, уменьшать длину только на непустой строке, TX `BS SPACE BS`.
2. Манифест в [`tests/con_session.4th`](../tests/con_session.4th); строка в [`tests/con_core_test.4th`](../tests/con_core_test.4th).
3. JSON словаря через [`doc/j1-word-graph/build.py`](j1-word-graph/build.py) (`fsys-<id>*.json`).
4. Каждое имя JSON помечено в [`tests/con_words.py`](../tests/con_words.py) (`run` / `colon` / `skip` с причиной).
5. Слова только этого id — в отдельном `*_test.4th` (см. [`tests/avr_con_test.4th`](../tests/avr_con_test.4th)). Общий echo/BS/`+`/`.s`/`: `/`words` не копировать.

```bash
export FSOC_HOME="$PWD"
cd tests && gforth con_core_test.4th
# или из корня:
fmix test
```

AVR в CI — soft body Verilator ([avr-soft.md](avr-soft.md)), не simavr. Тот же ISA, другое тело (например `j1abs` — порт `j1a`): ряд `con_core` не добавлять; прогнать скрипт словаря порта на новом ядре.

Новый fasm id MUST: автоген `disasm.4th` (`isa-gen-disasm`), golden (`gen-golden`), двусторонний round-trip (A→D walk + D→A same hex), `ic-check` coverage.

## Перед ревью: три сеанса эмуляции

Зелёный короткий `*_test.4th` — ещё не handoff. Нужны три лога (spec `forth-cross`):

1. Baremetal `blinky` + `cpu:`, `FSOC_EMU_CON=pin FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1`. В логе `pin led 0` и `pin led 1` каждый не меньше двух раз. Один импульс и стоп — провал.
2. Soc с lamp/blink этого id, те же pin-настройки. Оба уровня повторяются. Если образ печатает текст — в логе и on, и off. ` ok` не обязателен.
3. Soc `s" fsys" sys:` отвечает на `words` именами словаря образа и минимум двумя выражениями (`1 2 + .` → `3  ok`, плюс колон или `.s`). Новый kernel id: прогнать его ряд `con_core`, не только добавить файл. Тот же ISA, другое тело: скрипт порта (например `gforth tests/j1abs_words.4th`). Долгий скрипт не класть в `*_test.4th` (чтобы `fmix` не молчал минутами); на этом шаге всё равно запустить.

Для ручной проверки консоли не экспортировать `FSOC_EMU_UART_GAP`.

## Связанное

- Карта дерева: [MAP.md](MAP.md)
- Участие: [CONTRIBUTING.md](../CONTRIBUTING.md)
- Контракт агента (тот же canvas + отладочные ловушки): [`.cursor/rules/fsoc-cpu-target.mdc`](../.cursor/rules/fsoc-cpu-target.mdc), навык `add-cpu-target`
