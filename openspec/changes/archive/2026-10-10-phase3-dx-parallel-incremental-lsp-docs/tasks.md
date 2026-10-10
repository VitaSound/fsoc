# Tasks

## 1. Incremental Build Cache (`fsoc/incremental.4th`)

- [ ] 1.1 Create `fsoc/incremental.4th` with `cache-hash`, `cache-lookup`, `cache-restore`, `cache-store`, `cache-prune`; use `sha256sum` / `openssl dgst -sha256` via `sh-run`; verify loads
- [ ] 1.2 Implement hash computation: collect all input files for a step (target.4th, board, design, cpu profile, kernel sources, firmware sources, toolchain versions); produce deterministic SHA256; test with known inputs
- [ ] 1.3 Implement cache directory structure: `.fsoc-cache/<hash>/manifest.json` + output files; `cache-store` writes manifest and copies outputs; `cache-restore` copies back to project dir
- [ ] 1.4 Add LRU eviction in `cache-prune`: read all manifest.json, sort by atime, delete oldest until total size < limit (default 1GB, configurable via `FSOC_CACHE_SIZE` env)
- [ ] 1.5 Integrate into `fsoc/build.4th`: wrap each major step (fhdlgen, cross-compile, hex-gen, quartus, verilator) with cache lookup/restore/store; add `--no-incremental` flag to bypass
- [ ] 1.6 Write test `tests/incremental_test.4th`: build project twice, second time verify cache hit (log shows "cache hit"), modify target.4th, verify cache miss; run `fmix test tests/incremental_test.4th`

## 2. Parallel Build (`fsoc/parallel.4th`)

- [ ] 2.1 Create `fsoc/parallel.4th` with `build-plan` (collect all projects or single project steps), `topo-sort` (dependency graph: shared design → shared fhdlgen), `parallel-execute` (generate shell commands, pipe to `xargs -P N`)
- [ ] 2.2 Implement `fsoc-build-one` entry point: `gforth -e "s\" <project>\" s\" <step>\" included fsoc/build_one.4th"` — executes single build step with isolated context
- [ ] 2.3 Add file locking for shared outputs: `flock -x <project>/.build.lock` around fhdlgen/quartus steps; test with two workers needing same design
- [ ] 2.4 Add `--jobs N` / `-j N` parsing in `fsoc/fsoc.4th`; default to `nproc`; validate N > 0
- [ ] 2.5 Progress reporting: each worker prints `[worker N] <project>: <step>` with timestamp; verify output with `fsoc --build --jobs 4 --verbose`
- [ ] 2.6 Test parallel build: `cd projects && fsoc --build --jobs 4` (builds all projects); verify all complete, no race conditions, outputs identical to sequential

## 3. Isolated Test Runner (`tests/runner.4th`)

- [ ] 3.1 Create `tests/runner.4th`: discovers `tests/*_test.4th`, creates temp dir per test via `mktemp -d`, populates with fixture (`tests/fixture.4th` creates minimal project structure)
- [ ] 3.2 Create `tests/runner_inner.4th`: receives temp dir and test name, loads test file, runs `test-setup`/`test-teardown`, exits with 0 on pass, non-zero on fail
- [ ] 3.3 Implement parallel execution: `xargs -P N` over test list; each test runs in separate Gforth process
- [ ] 3.4 Result aggregation: collect exit codes, print summary `Ran X tests: P passed, S skipped, F failed in T.tss`
- [ ] 3.5 Backward compatibility: `FSOC_TEST_ISOLATED=1 gforth tests/soc_test.4th` works in isolation; without env var works in old mode (for debugging)
- [ ] 3.6 Update `fmix test` to use new runner with `--jobs` flag; verify `fmix test --jobs 4` runs all tests in parallel, same pass/fail as sequential
- [ ] 3.7 Migrate existing tests to use runner fixtures: ensure `tests/fixture.4th` provides all needed setup (board, cpu, design mocks)

## 4. Auto-Documentation (`doc/generate.py`)

- [ ] 4.1 Write Python script `doc/generate.py`: scans `fsoc/**/*.4th`, `boards/*.4th`, `designs/*.4th`, `cpu/**/*.4th`, `fsys/**/*.4th`, `targets/*.4th`
- [ ] 4.2 Extract stack effects: regex for `\ word-name ( before -- after )  Description` before `:` / `variable` / `defer` / `create` / `module:` / `export`
- [ ] 4.3 Generate `doc/generated/api/<module>.md` with table: Word | Stack Effect | Description
- [ ] 4.4 Generate `doc/generated/cpu-comparison.md`: parse `cpu.4th` profiles (regex for `s" <id>" cpu-new` + subsequent field setters)
- [ ] 4.5 Generate `doc/generated/boards/<board>.md`: parse board files (regex for `io-begin`, `pins`, `iostd`, `active-low`, `plat-clock-hz`, `subsignal`)
- [ ] 4.6 Generate `doc/generated/tasks.md`, `targets.md`, `options.md` from registries (load fsoc in Gforth, iterate ulists, output JSON, Python reads JSON)
- [ ] 4.7 Add `doc/generate.4th` wrapper calling Python script; verify `gforth doc/generate.4th` produces all files in `doc/generated/`
- [ ] 4.8 Add `fmix doc` command to run generation; verify output looks correct

## 5. LSP Support (`fsoc/lsp.4th`)

- [ ] 5.1 Create `fsoc/lsp.4th`: JSON-RPC 2.0 loop on stdin/stdout using `fjson` for parsing/serialization
- [ ] 5.2 Implement indexer: on startup, scan all `.4th` files, build symbol table (word → {file, line, kind, stack-effect, doc})
- [ ] 5.3 Implement `initialize` handler: return capabilities (textDocumentSync, hoverProvider, definitionProvider, completionProvider)
- [ ] 5.4 Implement `textDocument/definition`: lookup symbol, return Location (file URI, range)
- [ ] 5.5 Implement `textDocument/hover`: lookup symbol, return MarkdownContent with stack effect and doc
- [ ] 5.6 Implement `textDocument/completion`: filter symbols by prefix, return CompletionItem[] for tasks, targets, cpus, boards, options, words
- [ ] 5.7 Test with VS Code: create `.vscode/extensions/fsoc-lsp/package.json` with LSP config; verify go-to-definition, hover, completion work in `target.4th` and `fsoc/*.4th`
- [ ] 5.8 Add `fsoc.lsp.fsocHome` config support for custom FSOC_HOME

## 6. Integration & Verification

- [ ] 6.1 Run full test suite: `fmix test --jobs 4` — all tests pass
- [ ] 6.2 Run linter: `flint lint . --strict --project-only` — no errors
- [ ] 6.3 Test incremental build: `cd projects/soc_emul && fsoc --build` (cold), `fsoc --build` (cache hit, <5s), modify `target.4th`, `fsoc --build` (cache miss, rebuild)
- [ ] 6.4 Test parallel build: `fsoc --build --jobs 8` from repo root — all projects build concurrently
- [ ] 6.5 Test LSP in VS Code: open fsoc repo, verify completions for `task:`, `target:`, `cpu:`, `board:`, `option:` in target.4th; hover on `fsoc-path` shows stack effect; go-to-definition on `blinky-emit` jumps to `fsoc/tasks/blinky.4th`
- [ ] 6.6 Verify generated docs: `doc/generated/api/fsoc.paths.md` has `fsoc-path`, `fsoc-root`, `fsoc-basename`; `doc/generated/cpu-comparison.md` has 10 CPU rows; `doc/generated/boards/colorlight_5a_75e_v6_0.md` has 3 resources
- [ ] 6.7 Update `CHANGELOG.md`, `README.md` with new flags (`--jobs`, `--no-incremental`, `fmix test --jobs`, `fmix doc`)
- [ ] 6.8 Run `openspec validate` on the change — no errors