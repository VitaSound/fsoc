# Design

## Context

Phase 1-2 завершены: модульная архитектура, протоколная диспетчеризация, build context, декларативный DSL. Кодовая база готова к параллелизму (нет глобального состояния в сборке) и инкрементальности (детерминированные входы). Phase 3 добавляет DX фичи: параллельные сборки, инкрементальный кэш, изолированные тесты, автодокументация, LSP.

## Goals / Non-Goals

**Goals:**
- `fsoc --jobs N` — параллельная сборка независимых проектов/таргетов
- `fsoc --build` с инкрементальным кэшем (SHA256 входов) — skip unchanged steps
- `fmix test --jobs N` — параллельные изолированные тесты в отдельных Gforth процессах
- `doc/generate.4th` — генерация Markdown API reference, CPU/board/task tables из исходников
- `fsoc/lsp.4th` — LSP сервер для Gforth (definition, hover, completion)

**Non-Goals:**
- Распределённые сборки (remote workers)
- Полноценный LSP с semantic tokens, refactoring, diagnostics
- IDE plugin (только LSP сервер, клиент — на стороне редактора)
- Кэширование между разными машинами (только локальный `.fsoc-cache/`)

## Decisions

### 1. Parallel Build: xargs-based worker pool
**Почему:** Gforth не имеет нативных потоков. Простейший подход — собрать список команд сборки для каждого проекта/таргета, подать в `xargs -P N -I {} sh -c {}`.
**Алгоритм:**
1. `fsoc --build --jobs N` читает все `projects/*/target.4th` (или конкретный проект если запущен из проекта)
2. Для каждого проекта строит план: список шагов (fhdlgen, cross, hex, quartus, verilator) с зависимостями
3. Топологическая сортировка → уровни параллелизма
4. Каждый уровень = список независимых команд → `xargs -P N`
5. Команды выполняют `fsoc-build-one <project-dir> <step>` где `fsoc-build-one` — новая точка входа, выполняющая один шаг с изолированным `build-ctx`

**Альтернативы:**
- GNU `parallel` — не везде установлен
- Встроенный пул в Gforth через `fork`/`pipe` — сложно, непереносимо
- `xargs` — везде есть, прост, работает

**Файловая блокировка:** для shared outputs (fhdlgen output для shared design) используем `flock -x <dir>/build.lock` внутри `fsoc-build-one`.

### 2. Incremental Build: content-addressed cache
**Ключ кэша:** SHA256 от конкатенации:
- Содержимое всех входных файлов (target.4th, board.4th, design.4th, cpu.4th, kernel/*.4th, firmware/*.fs, fhdlgen binary)
- Версии инструментов: `fhdlgen --version`, `gforth --version`, `verilator --version`, `quartus_sh --version`
- CLI флаги, влияющие на вывод: `--jobs`, `--no-incremental` (не влияют на результат)

**Структура кэша:**
```
.fsoc-cache/
  <hash>/
    manifest.json    # { "step": "fhdlgen", "inputs": [...], "outputs": ["top.v", "includes.lst"] }
    top.v
    includes.lst
    ...
```

**Инвалидация:** при `--build` вычисляем хеш для каждого шага. Если `.fsoc-cache/<hash>/manifest.json` существует и все выходные файлы на месте → копируем из кэша. Иначе запускаем шаг, по завершении создаём новую запись кэша.

**LRU eviction:** при превышении лимита (default 1GB) удаляем старые записи по `atime` манифеста.

**Реализация:** `fsoc/incremental.4th` с словами:
- `cache-hash ( step-name project -- hash )` — вычисляет хеш
- `cache-lookup ( hash -- flag )` — проверяет кэш
- `cache-restore ( hash project -- )` — копирует файлы из кэша
- `cache-store ( hash step-name project -- )` — сохраняет выходы в кэш
- `cache-prune ( -- )` — LRU eviction

### 3. Isolated Test Runner: per-test Gforth process
**Архитектура:** `tests/runner.4th` — главный скрипт, запускаемый через `fmix test`:
1. Сканирует `tests/*_test.4th` (исключая fixture)
2. Для каждого теста: создаёт временную директорию `mktemp -d`, копирует туда fixture (`tests/fixture.4th` создаёт minimal project structure)
3. Запускает: `gforth -e "s\" <tempdir>\" s\" <testname>\" included tests/runner_inner.4th"`
4. `runner_inner.4th` загружает тест, выполняет, возвращает exit code
5. Собирает результаты, печатает summary

**Параллелизм:** `xargs -P N` над списком тестов. Каждый тест — отдельный процесс, полная изоляция.

**Обратная совместимость:** `gforth tests/soc_test.4th` продолжает работать — тест проверяет `FSOC_TEST_ISOLATED` env var, если не установлен — работает в старом режиме (для отладки).

### 4. Auto-Documentation: static analysis of Forth source
**Парсинг:** простой line-by-line сканер (не full parser). Ищет паттерны:
- `\ word-name ( before -- after )  Description` — перед определением `: word-name`
- `variable name  \ Description` / `create name  \ Description`
- `defer name  \ Description`
- `module: name  \ Description` / `export name  \ Description`

**Генерация:**
- `doc/generated/api/<module>.md` — таблица слов модуля
- `doc/generated/cpu-comparison.md` — парсит `cpu.4th` профили (regex по `s\" <id>\" cpu-new` и последующим полям)
- `doc/generated/boards/<board>.md` — парсит `boards/<board>.4th` (regex по `io-begin`, `pins`, `iostd`, `active-low`, `plat-clock-hz`)
- `doc/generated/tasks.md` — из `fsoc-tasks` registry
- `doc/generated/targets.md` — из `fsoc-targets` registry
- `doc/generated/options.md` — из `config-specs` registry

**Инструмент:** `doc/generate.4th` на Gforth, или Python скрипт (проще для regex). Python предпочтительнее — не требует загрузки всего fsoc образа.

### 5. LSP Server: JSON-RPC on stdio
**Архитектура:** `fsoc/lsp.4th` — Gforth программа, читает stdin построчно (JSON-RPC), пишет stdout.
**Индекс:** при старте сканирует все `.4th` файлы, строит словарь:
```
symbol -> { file, line, kind (word|variable|defer|constant|module|task|target|cpu|board|option), stack-effect?, doc? }
```
**Обработчики:**
- `initialize` → capabilities
- `textDocument/definition` → lookup symbol, return Location
- `textDocument/hover` → lookup symbol, return Markdown с stack effect и doc
- `textDocument/completion` → filter symbol table по prefix, возвращать CompletionItem[]
- `textDocument/didChange` → инкрементальное обновление индекса (опционально v1)

**Парсинг для индекса:** тот же сканер, что и для документации. Можно вынести в общий модуль `fsoc/symbol-index.4th`.

**Запуск:**.editorconfig / VS Code settings:
```json
"fsoc.lsp.command": "gforth",
"fsoc.lsp.args": ["${workspaceFolder}/fsoc/lsp.4th"]
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| `xargs` не переносим на Windows (WSL OK) | Добавить fallback: если `xargs -P` недоступен → последовательный запуск с предупреждением |
| Кэш растёт неконтролируемо | Hard limit 1GB + LRU; `--clean` удаляет кэш; опция `--cache-size` для настройки |
| LSP на Gforth медленный (парсинг при старте) | Индекс строится раз за сессию; для 150 файлов < 2с. Можно кэшировать индекс в `.fsoc-lsp-index/` |
| JSON-RPC в Gforth — нет библиотек | Минимум: парсить `{"jsonrpc":"2.0","id":1,"method":"..."}` через `fjson` (уже есть в депах) |
| Изолированные тесты медленнее (process spawn) | Параллелизм компенсирует; для разработки можно запускать один тест напрямую в Gforth |
| Автодокументация пропускает слова без комментариев | Это фича: заставляет документировать публичный API. Приватные слова не попадают в docs. |

## Migration Plan

1. Создать `fsoc/incremental.4th` с кэш API; интегрировать в `fsoc/build.4th` для каждого шага (fhdlgen, cross, hex, quartus, verilator)
2. Добавить `--jobs` / `--no-incremental` в `fsoc/fsoc.4th` CLI parsing
3. Реализовать `fsoc-build-one` entry point для параллельных воркеров
4. Создать `fsoc/parallel.4th` с топологической сортировкой и `xargs` запуском
5. Создать `tests/runner.4th` + `tests/runner_inner.4th`; мигрировать `fmix test` на новый раннер
6. Написать `doc/generate.py` (Python) для генерации docs; интегрировать в `fmix doc` или отдельную команду
7. Создать `fsoc/lsp.4th` с JSON-RPC loop и индексером; тестировать с VS Code
8. `fmix test --jobs 4` — полный прогон
9. Обновить `CHANGELOG.md`, `README.md` с новыми флагами
10. `openspec validate`

## Open Questions

- Нужен ли `fsoc-build-one` как отдельная CLI команда или внутренняя функция? (внутренняя, вызывается через `gforth -e "s\" project\" s\" step\" included fsoc/build_one.4th"`)
- Кэшировать ли Verilator симуляцию? (только сборку `obj_dir/Vtop_feed`; симуляция всегда запускается fresh)
- LSP: поддерживать ли `workspace/didChangeConfiguration` для динамического `FSOC_HOME`? (v1 — нет, читать env при старте)
- Документация: генерировать ли для `fsys/kernel/*` и `fsys/fasm/*`? (да, как отдельные модули)