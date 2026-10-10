# Design

## Context

См. proposal.md — Why. Сейчас:
- `cg-register` / `cg.emit` уже диспетчеризует по коду CG (`F` → `cg-f`, `I` → `soc-cg-i`, `E` → `cg-halt`).
- Внутри `cg-f` и `blinky-mcu-f` остаётся лестница `cpu.id$` + `compare` по `avr`/`bcpu`/`cd16`/`msl16`/`z80`.
- Pinmap: почти одинаковые блоки в `blinky-map-board`, `soc-map-board`, `bcpu-map`, `cd16-map`, `msl16-map`, `z80-map`.

Ограничения AGENTS / openspec config: пути от `FSOC_HOME`, `IF`/`abort"` только в определениях, строки через `fjson`/`fsoc-cat+`, без `setenv`.

## Goals / Non-Goals

**Goals:**
- Один механизм выбора CG=F entry point: xt на `cpu%`
- Общие pinmap helpers в `platform.4th` без изменения контракта `.qsf`
- Сохранить форматы образов и манифест

**Non-Goals:**
- modules / wordlist изоляция, typed-config, build-ctx, HDL DSL
- 10 глобальных `defer` (`cg-f-base`)
- parallel / incremental / LSP / auto-doc
- Рефакторинг CG=I / CG=E и `standalone.4th` pinmap (отдельные пути)

## Decisions

### 1. Два xt-поля на `cpu%`, не глобальные `defer`
**Выбор:** `field: cpu.cg-soc` и `field: cpu.cg-blinky` в конце `cpu%`.
**Почему:** несколько профилей CG=F живут в одном образе; глобальный `is` перезапишет соседний CPU. Xt на структуре — тот же паттерн, что `cg.emit`.
**Альтернативы:** один `cpu.cg-f` + task flag — хуже читается; таблица id→xt вне профиля — снова строковый ключ.

Регистрация после определения entry points (в конце соответствующего `cg-*.4th` или рядом с профилем, когда xt уже существует):

```forth
' avr-hex    cpu-find-avr cpu.cg-soc !
' avr-blinky cpu-find-avr cpu.cg-blinky !
```

Практичнее: слова-сеттеры `cpu-cg-soc` / `cpu-cg-blinky` на `current-cpu` в конце файла профиля после `include` задач, либо установка в том же файле, где определён xt, через `s" avr" cpu-find`.

### 2. `cg-f` и `blinky-mcu-f` — тонкие обёртки
```forth
: cg-f ( project cpu -- )
   dup cpu.cg-soc @ ?dup IF execute ELSE s" no cg-soc" cpu-stop THEN ;

: blinky-mcu-f ( project -- )
   dup soc-cpu-of { project cpu }
   cpu cpu.cg$ @ fsoc-fetch s" F" compare 0= IF
      cpu cpu.cg-blinky @ ?dup IF project cpu rot execute ELSE
         cpu s" no cg-blinky" cpu-stop THEN
   ELSE
      cpu s" blinky: not CG=F" cpu-stop
   THEN ;
```
Проверка CG=`F` в blinky остаётся (не CG=F MCU → abort); id-compare уходит.

### 3. Pinmap helpers — тонкие обёртки над `quartus-*`
Файл [`fsoc/platform-pinmap.4th`](fsoc/platform-pinmap.4th) подключается из `core.4th` **после** `targets/quartus.4th`, чтобы `quartus-map` был compile-time xt (runtime `find-name` ломается после SwapForth cross).

Сигнатуры:
- `board-map-clock ( signal-a signal-u -- )` — `plat-clock` → `request` → `quartus-map`
- `board-map-led ( signal-a signal-u -- )` — `user_led` 0 → `request` → `quartus-map`
- `board-map-uart ( tx-a tx-u rx-a rx-u -- )` — если `serial` есть: `request` + два `quartus-map-sub`; иначе выход
- `pin-map ( res-a res-u index signal-a signal-u -- )` — общий случай (`user_btn` и т.п.)

Без locals (только стек / `2variable` для uart): `soc-map-board` держит project под `>r`. Имя Quartus-проекта, `quartus-top`, `quartus-vfile`, `quartus-clock` остаются в задаче.

### 4. Порядок миграции
Сначала xt-поля + регистрация + перепись `cg-f`/`blinky-mcu-f`, затем helpers + замена тел `*-map*`. После каждого шага — точечный `--build` и в конце `fmix test`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Регистрация xt до определения слова | Ставить xt в конце `cg-*.4th` после `: avr-hex` / `: bcpu-soc`, не в середине `cpu.4th` |
| Рассинхрон периода такта между blinky и soc | Не трогать `quartus-clock` / period helpers — только pin map |
| Тест «нет compare» ловит легитимные строки | Проверять только блоки dispatch (`: cg-f` … `;` и `: blinky-mcu-f` … `;`), не весь файл |
| `standalone.4th` остаётся с копиями | Non-goal; не смешивать с этим change |

## Migration Plan

1. Расширить `cpu%`, добавить сеттеры / проверку нулевого xt.
2. Зарегистрировать xt для пяти CG=F профилей; упростить `cg-f` и `blinky-mcu-f`.
3. Добавить helpers в `platform.4th`; перевести blinky/soc/cg-* map.
4. `fmix test`; обновить `CHANGELOG.md`.
5. При archive — sync delta в `openspec/specs/forth-cross` и `platform`.
