# Design

## Context

Текущее состояние: `fsoc/core.4th` делает `included` 15+ файлов в одном образе; `cg-f.4th` диспетчеризирует CG=F через цепочку `s" avr" compare`; три задачи (`blinky.4th`, `soc.4th`, `cg-bcpu.4th`) имеют свои копии логики маппинга платформы; 6 CPU реализуют CG=F независимо с дублированием загрузки ядра, кросс-компилятора, extra-слоев, HEX генерации; опции манифеста нетипизированы (`option:` / `project.opt@`).

Ограничения (из AGENTS.md): пути только через `FSOC_HOME`; `setenv` в Gforth не вызывать; `IF`/`abort"` только внутри определений; `next-arg` копировать в свой буфер; fhdlgen вызывать через `${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen`; строки через `fjson.str-concat`/`fsoc-cat+`; списки через `ulist-each`.

## Goals / Non-Goals

**Goals:**
- Ввести модульную систему с явными `export`/`import` для изоляции пространств имён
- Вынести общий каркас CG=F в `cg-f-base.4th` с протоколом deferred-слов для CPU
- Объединить маппинг платформы в `platform.4th` через декларативные слова
- Ввести типизированную конфигурацию с валидацией и дефолтами
- Сохранить совместимость: существующие `target.4th` манифесты работают без изменений

**Non-Goals:**
- Изменение CLI (`fsoc.4th`) или формата `target.4th`
- Рефакторинг CG=I / CG=E эмиттеров (J1-семейство)
- Параллельные сборки или инкрементальность (Phase 2+)
- LSP/IDE поддержка (Phase 3)

## Decisions

### 1. Модульная система: словарь на базе `ulist` + `execute`
**Почему:** Gforth не имеет нативных модулей. `ulist` уже используется в `registry.4th` для задач/таргетов — применяем тот же паттерн.
**Альтернативы:**
- `vocabulary` / `definitions` — слишком тяжёлые, ломают `find-name` в тестах
- Препроцессор на Python — добавляет зависимость, нарушает «Forth-only»
**Решение:** `module:` создаёт запись в `module-registry` (ulist) с именем и списком экспортов (xt). `export` добавляет xt в список текущего модуля. `import` ищет модуль, находит экспорт, делает `name>interpret` в контексте импортера. `module-end` регистрирует модуль.

### 2. Загрузка модулей: топологическая сортировка зависимостей
**Почему:** Модули могут импортировать друг друга. Порядок `included` в `core.4th` неявный.
**Решение:** При первом `import` модуля запускаем DFS по его импортам (парсим исходник модуля на предмет `import` слов до `module-end`), загружаем зависимости рекурсивно, потом сам модуль. Кэшируем загруженные модули в `module-loaded?` таблице.

### 3. CG=F база: 10 deferred-слов как протокол
**Почему:** Все 6 CPU делают одно и то же: загрузить ядро → кросс → extra → hex → размер. Различия только в деталях каждого шага.
**Протокол (deferred слова, которые CPU должен установить):**
| Слово | Стек | Назначение |
|-------|------|------------|
| `cg-kernel-load` | `( project cpu -- )` | Загрузить ядро CPU (включить `kernel.4th`) |
| `cg-cross-load` | `( project cpu -- )` | Загрузить хостовый кросс-компилятор |
| `cg-extra-load` | `( project cpu blink? -- )` | Загрузить extra-слои (console/repl/blink) |
| `cg-hex-file` | `( project -- )` | Записать `firmware.hex` в формате CPU |
| `cg-size-report` | `( -- )` | Вывести строку размера |
| `cg-hw-note` | `( cpu -- )` | Вывести "Hardware: <cpu-ref> (<cpu-id>)" |
| `cg-asm-hex` | `( project cpu -- )` | Baremetal: скомпилировать blink firmware в hex |
| `cg-copy-leaves` | `( project -- )` | Скопировать листья Verilog (cpu.v, uart.v, ...) |
| `cg-top-module` | `( project -- )` | Записать `top-module` файл |
| `cg-map-board` | `( project -- )` | Смапить пины платы через `platform-pinmap` |

**Входные точки базы:**
- `cg-f-fsys` — для `soc` task с `sys: fsys`
- `cg-f-blinky` — для `blinky` task с `cpu:`
- `cg-f-hex` — общая hex-генерация (используется `cg-f-fsys`)

### 4. Platform pinmap: слова-делегаты к `quartus-*`
**Почему:** `quartus-project`, `quartus-top`, `quartus-vfile`, `quartus-clock`, `quartus-map`, `quartus-map-sub` уже есть в `targets/quartus.4th`. Новые слова — тонкие обёртки, которые делают `io-find` → `request` → `quartus-map*`.
**Решение:** Добавить в `platform.4th`:
```forth
: board-map-clock ( signal-name -- ) ... ;
: board-map-led ( signal-name active-low? -- ) ... ;
: board-map-uart ( tx-signal rx-signal -- ) ... ;
: pin-map ( res-name res-index signal-name -- ) ... ;
```
Существующие `blinky-map-board`, `soc-map-board`, `bcpu-map` заменяются на вызовы этих слов.

### 5. Typed config: схема в `config-specs` ulist
**Почему:** `project.opts` уже ulist. Добавляем параллельный реестр `config-specs` с метаданными.
**Структура `config-spec%`:**
```forth
begin-structure config-spec%
    field: spec.name$     \ string
    field: spec.type      \ string|int|bool|enum
    field: spec.default   \ allocated string или 0
    field: spec.validate  \ xt: ( value-a value-u -- flag )
    field: spec.doc       \ allocated string
end-structure
```
`config-define` создаёт запись в `config-specs`. `config-get` ищет в `project.opts`, если нет — берёт `spec.default`, прогоняет через `spec.validate`, возвращает значение.

**Валидаторы:**
- `validate-bool`: принимает `0`/`1`/`true`/`false`/`yes`/`no`
- `validate-int`: `s>number?`, опционально проверка диапазона
- `validate-pin`: `validate-int` + проверка что пин существует на плате
- `validate-enum`: проверка вхождения в список (enum значения хранятся в `spec.default` как строка "debug|release")
- `validate-model`: проверка существования файла `fsys/fasm/avr/<model>.4th`

### 6. Миграция задач: по одной за раз, тесты после каждой
**Порядок:**
1. `fsoc/modules.4th` — новая инфраструктура, тесты загрузки
2. `fsoc/config.4th` — новая инфраструктура, тесты валидации
3. `fsoc/platform.4th` — добавить pinmap слова, тесты `platform_test.4th`
4. `fsoc/tasks/cg-f-base.4th` — новая база, unit-тесты протокола
5. `fsoc/tasks/cg-f.4th` — перевести на `cg-f-base` (avr, bcpu, cd16, msl16, z80)
6. `fsoc/tasks/blinky.4th` — заменить `blinky-map-board` на pinmap
7. `fsoc/tasks/soc.4th` — заменить `soc-map-board` на pinmap, `cg-f` на `cg-f-base`
8. `fsoc/tasks/cg-bcpu.4th` — реализовать 10 deferred-слов, удалить дубликат
9. Аналогично `cg-cd16.4th`, `cg-msl16.4th`, `cg-z80.4th`
10. `fsoc/core.4th` — перевести `included` на `module:` / `import`
11. `fsoc/load.4th` — загружать модули вместо `included`

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Модульная система ломает `find-name` в существующих тестах | Постепенная миграция: сначала новые модули, старые файлы через `included` внутри модулей. Тесты `builder_test.4th` проверяют разрешение имён. |
| Deferred-слова CG=F не установлены у какого-то CPU | В `cpu.4th` при регистрации CPU проверять наличие всех 10 deferred-слов для CG=F профилей; `abort"` с именем слова. |
| `config-get` меняет семантику: раньше `option:` без дефолта давал `0 0`, теперь дефолт | В `config-define` для существующих опций ставить дефолт `0 0` (пустая строка). `config-get` возвращает дефолт только если опция отсутствует — поведение совпадает. |
| Топологическая загрузка модулей замедляет старт | Модулей ~20. DFS один раз при старте билдера — не измеримо по сравнению с fhdlgen/Verilator. Кэш `module-loaded?` убирает повторные загрузки. |
| `board-map-*` требуют загруженную платформу | Существующий код уже делает `board-load` перед маппингом. Новые слова делают `current-platform @ 0= IF EXIT THEN` — то же поведение. |

## Migration Plan

1. Создать новые файлы: `modules.4th`, `cg-f-base.4th`, `config.4th`
2. Добавить pinmap слова в `platform.4th`
3. Написать unit-тесты для каждого нового компонента
4. Мигрировать CPU профили по одному: bcpu → cd16 → msl16 → z80 → avr
5. Мигрировать задачи: blinky → soc
6. Перевести `core.4th` / `load.4th` на модули
7. `fmix test` — полный прогон
8. `flint` — линтинг
9. Обновить `CHANGELOG.md`

## Open Questions

- Нужно ли версионирование модулей? (пока нет — внутренний инструмент)
- Поддерживать ли `import` с переименованием конфликтующих имен? (да, текущий дизайн `import foo.4th foo-bar my-bar` это позволяет)
- Выносить ли `config-specs` в отдельный файл для переиспользования? (пока в `config.4th`)