# Design

## Context

После Phase 1: модульная загрузка работает, CG=F база используется всеми CPU, pinmap унифицирован, typed config активен. Остаются: CG диспетчеризация через строки в `cg-f.4th`/`cg-i-blink.4th`/`soc.4th`, 20+ глобальных переменных состояния сборки, императивный HDL DSL в `designs/*.4th`. Phase 2 устраняет это.

## Goals / Non-Goals

**Goals:**
- Function pointer dispatch в `cpu%` для всех CG кодов
- `build-ctx%` структура вместо глобальных переменных состояния
- Декларативный HDL DSL (`hdl-design`, `component`, `instance`, `connect`, `param`)
- Полная обратная совместимость: старый код работает без изменений

**Non-Goals:**
- Параллельные сборки (Phase 3)
- Инкрементальность (Phase 3)
- Изменение fhdlgen IR или CLI
- Рефакторинг `targets/*.4th` (Quartus/Yosys/Verilator остаются как есть)

## Decisions

### 1. Protocol Dispatch: расширение `cpu%` function pointers
**Почему:** `cg-find` по строке CG кода + `cg.emit @ execute` работает, но требует строковые сравнения в задачах для выбора entry point (cg-f vs cg-i-blink vs cg-halt). Function pointers в `cpu%` дают единый механизм.
**Поля `cpu%` (добавить в конец):**
```forth
field: cpu.cg-hex      \ ( project cpu -- )  для CG=F hex generation (soc/blinky)
field: cpu.cg-blinky   \ ( project cpu -- )  для CG=F baremetal blinky
field: cpu.cg-soc      \ ( project cpu -- )  для CG=F soc fsys image
field: cpu.cg-i-blink  \ ( project cpu -- )  для CG=I blink (J1 family)
field: cpu.cg-halt     \ ( project cpu -- )  для CG=E (no hex)
```
**Регистрация в `cpu.4th`:**
```forth
s" avr" cpu-new
... 
' avr-hex      cpu.cg-hex !
' avr-blinky   cpu.cg-blinky !
' avr-fsys     cpu.cg-soc !
0              cpu.cg-i-blink !  \ CG=F, не CG=I
' cg-halt      cpu.cg-halt !

s" j1a" cpu-new
...
0              cpu.cg-hex !      \ CG=I, не CG=F
0              cpu.cg-blinky !
0              cpu.cg-soc !
' soc-cg-i     cpu.cg-i-blink !  \ CG=I entry point
' cg-halt      cpu.cg-halt !
```
**Диспетчеризация в задачах:**
```forth
: cg-f ( project cpu -- )
    cpu.cg-hex @ ?dup IF execute ELSE cg-halt THEN ;

: cg-i-blink ( project cpu -- )
    cpu.cg-i-blink @ ?dup IF execute ELSE cg-halt THEN ;

: soc-cg-dispatch ( project cpu -- )
    cpu.cg-soc @ ?dup IF execute ELSE cpu.cg-hex @ ?dup IF execute ELSE cg-halt THEN ;
```
**Альтернативы:** оставить `cg-find` по строке — сохраняет indirection но требует строковые сравнения в задачах. Function pointers проще и быстрее.

### 2. Build Context: `build-ctx%` структура
**Почему:** 20+ переменных (`soc-cpu`, `soc-clk`, `soc-board-top?`, `soc-view?`, `blinky-clk`, `avr-want-blink`, `avr-want-repl`, `target-reg-sim`, `opt-find-*`, `reg-find-*`, `find-io-*`, `plat-clock-*`, `leaf-*`, `flatten-*`, `bcpu-*`) создают неявные зависимости.
**Структура:**
```forth
begin-structure build-ctx%
    field: ctx.project        \ project
    field: ctx.cpu            \ cpu
    field: ctx.platform       \ platform (0 если нет)
    field: ctx.target         \ target
    field: ctx.board-clock-io \ io (clock resource)
    field: ctx.options        \ ulist: option name -> value
    field: ctx.task           \ task (blinky/soc/standalone)
    field: ctx.board-top?     \ flag: generate board top
    field: ctx.view?          \ flag: generate view (emulation)
    field: ctx.uart-gap?      \ flag/uart-gap value
    field: ctx.blink?         \ flag: blink option
    field: ctx.release?       \ flag: image=release option
end-structure
```
**Создание:** `build-ctx-new ( project -- ctx )` в `fsoc-build`:
```forth
: build-ctx-new ( project -- ctx )
    build-ctx% allocate throw >r
    r@ ctx.project !
    r@ project.cpu@ cpu-find r@ ctx.cpu !
    r@ project board-load r@ ctx.platform !
    r@ project.target@ target-find r@ ctx.target !
    r@ ctx.platform @ 0= IF 0 ELSE
        r@ ctx.platform @ plat-clock r@ ctx.board-clock-io !
    THEN
    r@ project.opts @ r@ ctx.options !  \ copy ulist
    r@ project task-of r@ ctx.task !
    0 r@ ctx.board-top? !
    0 r@ ctx.view? !
    r@ ctx.cpu @ cpu.uart-gap @ ?dup IF r@ ctx.uart-gap? ! ELSE 0 r@ ctx.uart-gap? ! THEN
    s" blink" r@ project opt@ s" 1" compare 0= r@ ctx.blink? !
    s" image" r@ project opt@ s" release" compare 0= r@ ctx.release? !
    r> ;
```
**Миграция задач:** каждая `task.emit` меняет сигнатуру с `( project -- )` на `( ctx -- )`. Внутри читают из ctx. `fsoc-build` создаёт ctx один раз, передаёт в `task.emit`, `target.emit`, `target.run`.

### 3. Declarative HDL DSL: `fsoc/hdl-dsl.4th`
**Почему:** Императивный стиль (`hdl-project` → `hdl-module` → `hdl-instance` → `inst-connect` × N) громоздок, трудно читать иерархию. Декларативный стиль описывает структуру, а не последовательность вызовов.
**Архитектура:** DSL компилируется в тот же fhdlgen IR, что и старый API. `hdl-dsl.4th` предоставляет слова, которые накапливают AST в буфере, затем `end-design` прогоняет кодген.
**AST структура (в памяти):**
```forth
begin-structure dsl-design%
    field: dsl.name$
    field: dsl.components  \ ulist of dsl-component%
    field: dsl.instances   \ ulist of dsl-instance%
    field: dsl.top-module  \ string
end-structure

begin-structure dsl-component%
    field: comp.name$
    field: comp.core-file    \ 0 или file string
    field: comp.wrap-file    \ 0 или file string
    field: comp.extra-files  \ ulist of file strings
    field: comp.condition    \ 0 или flag
    field: comp.includes     \ ulist of .v files
    field: comp.ports        \ ulist of (name dir) pairs
end-structure

begin-structure dsl-instance%
    field: inst.name$
    field: inst.comp-name$
    field: inst.params       \ ulist of (name value)
    field: inst.connections  \ ulist of (local-sig remote-sig invert?)
end-structure
```
**Кодген (`end-design`):** проходит по components → `hdl-include-v`, `hdl-blackbox`, `in-port`/`out-port`; затем `hdl-module` для top → `hdl-instance` с `hdl-inst-param` и `inst-connect`.
**Совместимость:** старый `hdl.4th` не меняется. `designs/*.4th` могут `s" fsoc/hdl-dsl.4th" included` и использовать новый синтаксис. Постепенно мигрируем дизайны.

**Пример `designs/soc_top.4th` (декларативный):**
```forth
hdl-design soc
  top-name top
  src-file designs/soc_top.4th

  component j1-wrap
    core   soc-kit-core
    wrap   soc-kit-wrap
    extra  lib/j1_wrap.4th
  end-component

  component uart
    condition hdl-no-uart? 0=
    include uart.v
    ports uart_rx in uart_tx out
  end-component

  component timer
    include timer.v
  end-component

  component regio
    include regio.v
  end-component

  instance top j1-wrap
    param USE_TIMER   1
    param USE_REGIO   1
    param CLK_HZ      CLK_HZ?
    param BAUD        BAUD?
    param TIMER_DIV   TIMER_DIV?
    connect clk     clk
    connect rst     rst_dump?
    connect uart_rx uart_rx?
    connect uart_tx uart_tx?
    connect led     led (invert: LED_LOW?)
  end-instance
end-design
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Function pointers в `cpu%` ломают существующие CPU профили | Добавить поля в конец `cpu%` (не сдвигают существующие). В `cpu.4th` после регистрации CPU установить все 5 указателей (0 для неприменимых). Тест `cpu_test.4th` проверяет что все CG=F профили имеют ненулевые `cg-hex`/`cg-blinky`/`cg-soc`. |
| `build-ctx%` требует изменения сигнатур во всех задачах | Постепенная миграция: 1) добавить `build-ctx.4th`, 2) обновить `fsoc-build` создавать ctx, 3) по одной задаче менять сигнатуру и тело. Старые задачи через shim `( project -- ) ctx project build-ctx-new swap execute` пока не мигрированы. |
| DSL кодген должен производить бит-в-бит идентичный `top.v` | Unit-тест: сгенерировать оба варианта для `soc_top.4th`, `diff` выходных файлов. Любая разница — баг в DSL кодгене. |
| DSL condition/optional connection семантика | `condition` на компоненте: если false — компонент полностью исключается (как `hdl-no-uart?` сейчас). `connect` с `?` суффиксом: если remote signal resolves to 0 — соединение пропускается. Протестировать на Colorlight (нет serial). |

## Migration Plan

1. Создать `fsoc/build-ctx.4th` с `build-ctx%` и `build-ctx-new`
2. Обновить `fsoc/cpu.4th`: добавить 5 function pointer полей, заполнить при регистрации каждого CPU
3. Обновить `fsoc/tasks/cg-f.4th`: заменить строковые сравнения на `cpu.cg-hex @ execute` и т.д.
4. Обновить `fsoc/tasks/cg-i-blink.4th`: использовать `cpu.cg-i-blink @ execute`
5. Обновить `fsoc/tasks/soc.4th`: `soc-emit` использует `cpu.cg-soc @ execute` с fallback на `cg-hex`
5. Создать `fsoc/hdl-dsl.4th` с AST и кодгеном
6. Переписать `designs/soc_top.4th` на декларативный DSL (параллельно оставить старый как `soc_top_legacy.4th` для сравнения)
7. Мигрировать `fsoc/build.4th`: `fsoc-build` создаёт ctx, передаёт в task/target
8. По одной мигрировать задачи: `blinky.4th` → `soc.4th` → `standalone.4th` → `cg-f.4th` → `cg-bcpu.4th` и т.д.
9. Удалить глобальные переменные после миграции всех потребителей
10. `fmix test`, `flint`, верификация всех проектов из AGENTS.md

## Open Questions

- Нужен ли `ctx.harness`? (сейчас `project.harness$` — оставить в project)
- Выносить ли `build-ctx%` в отдельный файл или оставить в `build-ctx.4th`? (отдельный файл чище)
- Поддерживать ли DSL `generate` блоки для параметризованных компонентов? (пока нет — YAGNI)