# Proposal

## Why

Phase 1-2 создали модульную архитектуру, протоколную диспетчеризацию, контекстные объекты и декларативный DSL. Phase 3 фокусируется на developer experience: параллельные сборки (build context уже реентерабелен), инкрементальность (хеширование входов), изолированный test runner (параллельные тесты), автогенерация документации из Forth исходников, LSP/IDE stubs. Это сокращает время цикла edit-build-test и упрощает онбординг.

## What Changes

- **Parallel builds**: `fsoc --jobs N` — пул воркеров, каждый получает свой `build-ctx`, независимые задачи (blinky, soc, standalone) и таргеты (emulation, quartus, yosys) запускаются параллельно. Синхронизация через файловые блокировки на выходные артефакты.
- **Incremental builds**: манифест `target.4th` + все включённые файлы → SHA256; кэш в `.fsoc-cache/`; при `--build` сравниваем хеш, пропускаем неизменённые этапы (fhdlgen, cross-compile, hex gen). `--clean` удаляет кэш.
- **Isolated test runner**: `tests/runner.4th` — каждый тест в отдельном процессе Gforth с временным проектом, без глобального состояния. `fmix test --jobs N` параллелизует. Фикстуры через `tests/fixture.4th` создают изолированные sandbox.
- **Auto-documentation**: `doc/generate.4th` сканирует `fsoc/*.4th`, `fsoc/tasks/*.4th`, `designs/*.4th`, `boards/*.4th`, `cpu/*.4th` — извлекает stack effects из комментариев `\ word ( -- )`, генерирует Markdown API reference, CPU comparison tables, board pinout tables.
- **LSP/IDE stubs**: `fsoc/lsp.4th` — предоставляет `definition`, `hover`, `completion` для Gforth через Language Server Protocol (JSON-RPC на stdio). Минимум: go-to-definition для `:` слов, hover с stack effect, completion для зарегистрированных задач/таргетов/CPU/опций.

**BREAKING**: нет — CLI флаги additive (`--jobs`, `--no-incremental`), тесты совместимы.

## Capabilities

### New Capabilities
- `parallel-build`: пул воркеров с изолированными build contexts
- `incremental-build`: content-addressed cache с invalidation по хешам входов
- `isolated-test-runner`: per-test Gforth процессы, параллельное выполнение
- `auto-documentation`: генерация Markdown из Forth source комментариев
- `lsp-support`: Language Server Protocol для Gforth/fsoc

### Modified Capabilities
- `builder`: добавляет `--jobs`, `--no-incremental` флаги, пул воркеров
- `emulation`: поддерживает параллельные Verilator сборки

## Impact

**Затронутые файлы**:
- Новые: `fsoc/parallel.4th`, `fsoc/incremental.4th`, `tests/runner.4th`, `doc/generate.4th`, `fsoc/lsp.4th`
- Изменённые: `fsoc/fsoc.4th` (CLI flags), `fsoc/build.4th` (incremental checks), `fsoc.4th` (entry point), `tests/*.4th` (migrate to runner), `tools/pre-push.sh` (parallel test execution)
- Зависимости: `sha256sum` / `openssl dgst` для хешей, `xargs -P` / `gnu-parallel` для параллелизма (опционально, fallback на последовательный)