# Tasks

## 1. Module System (`fsoc/modules.4th`)

- [ ] 1.1 Create `fsoc/modules.4th` with `module:`, `module-end`, `export`, `import`, `module-registry` ulist, `module-loaded?` table; verify `gforth fsoc/modules.4th` loads without error
- [ ] 1.2 Implement topological load in `import`: DFS parse of imported module's source for `import` words before `module-end`, recursive load, cycle detection; verify with test module chain A→B→C
- [ ] 1.3 Add `module-find` (by name) and `module-exports` accessor; verify `import` resolves xt correctly and binds to new name
- [ ] 1.4 Write test `tests/modules_test.4th`: declare module with 2 exports, import with rename, verify both names work; verify missing module/export aborts with clear message; run `fmix test tests/modules_test.4th`
- [ ] 1.5 Ensure backward compatibility: legacy `included` file inside module works; test `s" legacy.4th" included` inside `module:` loads definitions into module namespace

## 2. Typed Config (`fsoc/config.4th`)

- [ ] 2.1 Create `fsoc/config.4th` with `config-spec%` structure, `config-specs` ulist, `config-define`, `config-get`, validators `validate-bool`, `validate-int`, `validate-pin`, `validate-enum`, `validate-model`; verify `gforth fsoc/config.4th` loads
- [ ] 2.2 Implement `config-get` fallback to `spec.default` when project option absent; run validator on retrieved value; return value as string
- [ ] 2.3 Define built-in configs for existing options: `led-bit` (int, default 0, validate-pin), `lamp` (bool, default false), `image` (enum, default debug, validate-enum "debug|release"), `model` (string, default empty, validate-model); verify definitions load
- [ ] 2.4 Write test `tests/config_test.4th`: define configs, create mock project with `option:`, call `config-get`, verify returned values, defaults, validation errors; run `fmix test tests/config_test.4th`
- [ ] 2.5 Add iteration word `config-iterate` for documentation generation; test it lists all 4 built-in configs with metadata

## 3. Platform Pinmap (`fsoc/platform.4th`)

- [ ] 3.1 Add `board-map-clock`, `board-map-led`, `board-map-uart`, `pin-map` to `fsoc/platform.4th` using existing `io-find`, `request`, `quartus-*` words; verify `gforth fsoc/platform.4th` loads
- [ ] 3.2 Each word handles `current-platform @ 0= IF EXIT THEN` for emulation targets; test by calling without platform loaded — silent exit
- [ ] 3.3 `board-map-led` emits `hdl-assign` `led = ~led_q` when `active-low?` true; verify generated assignment in test
- [ ] 3.4 `board-map-uart` uses `quartus-map-sub` for tx/rx sub-signals; verify with Colorlight board (no serial) — silent exit
- [ ] 3.5 Write test `tests/platform_pinmap_test.4th`: load test board (terasic_de0nano), call all 4 words, verify Quartus project has correct pin mappings; run `fmix test tests/platform_pinmap_test.4th`

## 4. CG=F Base (`fsoc/tasks/cg-f-base.4th`)

- [ ] 4.1 Create `fsoc/tasks/cg-f-base.4th` with 10 `defer` words per protocol table in design.md; verify file loads
- [ ] 4.2 Implement `cg-f-fsys` entry point: sequence `cg-kernel-load` → `cg-cross-load` → `cg-extra-load` (blink? from project option) → `cg-hex-file` → `cg-size-report`; verify stack effect `( project cpu -- )`
- [ ] 4.3 Implement `cg-f-blinky` entry point: `cg-hw-note` → `cg-asm-hex` → `cg-copy-leaves` → `cg-top-module` → `cg-map-board`; verify stack effect
- [ ] 4.4 Implement `cg-f-hex` entry point: shared hex generation used by `cg-f-fsys`; verify
- [ ] 4.5 Add CPU registration check in `cpu.4th`: when `cpu-cg` is `F`, verify all 10 deferred words are non-zero after CPU profile setup; abort with missing word name if not
- [ ] 4.6 Write test `tests/cg_f_base_test.4th`: mock CPU with minimal deferred implementations, call all 3 entry points, verify call sequence via tracer; run `fmix test tests/cg_f_base_test.4th`

## 5. Migrate CPU Profiles to CG=F Base

- [ ] 5.1 **bcpu**: In `fsoc/tasks/cg-bcpu.4th`, remove `bcpu-soc`, `bcpu-blinky`, `bcpu-fsys-image`, `bcpu-hex`, `bcpu-bytes`, `bcpu-hw`, `bcpu-asm`, `bcpu-leaf`, `bcpu-uart`, `bcpu-top!`, `bcpu-map`; implement 10 deferred words calling remaining logic; set deferred words in CPU profile registration; verify `cd projects/soc_bcpu && fsoc --build` works
- [ ] 5.2 **cd16**: Create `fsoc/tasks/cg-cd16.4th` (split from `cg-f.4th`), implement 10 deferred words; update CPU profile; verify `cd projects/soc_cd16 && fsoc --build`
- [ ] 5.3 **msl16**: Create `fsoc/tasks/cg-msl16.4th`, implement 10 deferred words; update CPU profile; verify `cd projects/soc_msl16 && fsoc --build`
- [ ] 5.4 **z80**: Create `fsoc/tasks/cg-z80.4th`, implement 10 deferred words; update CPU profile; verify `cd projects/soc_z80 && fsoc --build`
- [ ] 5.5 **avr**: In `fsoc/tasks/cg-f.4th`, extract avr-specific logic to `fsoc/tasks/cg-avr.4th`, implement 10 deferred words; update CPU profile; verify `cd projects/soc_atmega8 && fsoc --build` and `cd projects/baremetal/blinky_atmega && fsoc --build`

## 6. Migrate Tasks to Platform Pinmap

- [ ] 6.1 **blinky.4th**: Replace `blinky-map-board` with `board-map-clock` + `board-map-led` (active-low from `soc-led-low?`); remove `blinky-clk` variable; verify `cd projects/blinky_emul && fsoc --build` and `cd projects/blinky_terasic_de0nano && fsoc --build`
- [ ] 6.2 **soc.4th**: Replace `soc-map-board` with `board-map-clock` + `board-map-led` + `board-map-uart` (guarded by `soc-serial?`); remove `soc-clk` variable; verify `cd projects/soc_emul && fsoc --build` and `cd projects/soc_terasic_de0nano && fsoc --build`
- [ ] 6.3 **cg-bcpu.4th**: Replace `bcpu-map` with `board-map-clock` + `board-map-led` + optional `pin-map` for button (when `btn?`); verify `cd projects/soc_bcpu_colorlight && fsoc --build`

## 7. Migrate Core to Module System

- [ ] 7.1 Convert `fsoc/utils.4th`, `fsoc/paths.4th`, `fsoc/sh.4th`, `fsoc/log.4th`, `fsoc/project.4th`, `fsoc/registry.4th`, `fsoc/hdl.4th`, `fsoc/platform.4th`, `fsoc/build.4th`, `fsoc/core.4th`, `fsoc/kit.4th`, `fsoc/cpu.4th`, `fsoc/sys.4th`, `fsoc/compare.4th` to `module:` / `module-end` with explicit `export`; add `fsoc/modules.4th` to `fsoc/load.4th` first
- [ ] 7.2 Convert `fsoc/soc/region.4th`, `fsoc/soc/iomap.4th`, `fsoc/soc/nor.4th` to modules
- [ ] 7.3 Convert `fsoc/tasks/*.4th` to modules (each task file = one module)
- [ ] 7.4 Convert `targets/*.4th` to modules
- [ ] 7.5 Update `fsoc/load.4th` to load `modules.4th` then `import` each module instead of `included`; verify `fsoc version` and `fsoc --build` work from any project
- [ ] 7.6 Write test `tests/module_migration_test.4th`: verify all previously exported words still resolve via `find-name` after module migration; run `fmix test`

## 8. Integration Verification

- [ ] 8.1 Run full test suite: `fmix test` — all tests pass
- [ ] 8.2 Run linter: `flint lint . --strict --project-only` — no errors
- [ ] 8.3 Test all example projects from AGENTS.md:
  - `cd projects/baremetal/blinky_emul && fsoc --build`
  - `cd projects/baremetal/blinky_atmega && fsoc --build`
  - `cd projects/soc_emul && fsoc --build`
  - `cd projects/soc_emul_colorlight_5a_75e_v6_0 && fsoc --build`
  - `cd projects/soc_terasic_de0nano && fsoc --build`
  - `cd projects/soc_blink_colorlight_5a_75e_v6_0 && fsoc --build`
  - `cd projects/baremetal/blinky_terasic_de0nano && fsoc --build`
- [ ] 8.4 Update `CHANGELOG.md` with Phase 1 changes
- [ ] 8.5 Run `openspec validate` on the change — no errors