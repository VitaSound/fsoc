# Tasks

## 1. Protocol Dispatch: CPU Function Pointers

- [ ] 1.1 Add 5 function pointer fields to `cpu%` in `fsoc/cpu.4th`: `cpu.cg-hex`, `cpu.cg-blinky`, `cpu.cg-soc`, `cpu.cg-i-blink`, `cpu.cg-halt`; verify `gforth fsoc/cpu.4th` loads
- [ ] 1.2 Update each CPU profile registration in `cpu.4th` to set all 5 pointers:
  - j1a/j1b/j1abs: `cg-i-blink` = `soc-cg-i`, others 0, `cg-halt` = `cg-halt`
  - avr: `cg-hex` = `avr-hex`, `cg-blinky` = `avr-blinky`, `cg-soc` = `avr-fsys`, `cg-i-blink` = 0, `cg-halt` = `cg-halt`
  - bcpu/cd16/msl16/z80: `cg-hex` = `<cpu>-hex`, `cg-blinky` = `<cpu>-blinky`, `cg-soc` = `<cpu>-soc`, `cg-i-blink` = 0, `cg-halt` = `cg-halt`
  - stm8: all 0, `cg-halt` = `cg-halt`
  Verify `cd projects/soc_emul && fsoc --build` works for each CPU
- [ ] 1.3 Refactor `fsoc/tasks/cg-f.4th`: replace string dispatch chain with `cpu.cg-hex @ ?dup IF execute ELSE cg-halt THEN`; same for `cg-blinky`/`cg-soc` entry points; verify `fmix test tests/cpu_test.4th`
- [ ] 1.4 Refactor `fsoc/tasks/cg-i-blink.4th`: use `cpu.cg-i-blink @ ?dup IF execute ELSE cg-halt THEN`; verify J1 blink still works
- [ ] 1.5 Refactor `fsoc/tasks/soc.4th`: `soc-emit` calls `cpu.cg-soc @ ?dup IF execute ELSE cpu.cg-hex @ ?dup IF execute ELSE cg-halt THEN`; verify `cd projects/soc_emul && fsoc --build`
- [ ] 1.6 Add CPU registration validation: after `cpu-new` and profile setup, check that CG=F CPUs have non-zero `cg-hex`/`cg-blinky`/`cg-soc`; CG=I have `cg-i-blink`; abort with clear message if missing; test by temporarily clearing a pointer

## 2. Build Context (`fsoc/build-ctx.4th`)

- [ ] 2.1 Create `fsoc/build-ctx.4th` with `build-ctx%` structure and `build-ctx-new ( project -- ctx )` per design.md; verify loads
- [ ] 2.2 Add context accessors: `ctx.project@`, `ctx.cpu@`, `ctx.platform@`, `ctx.target@`, `ctx.board-clock-io@`, `ctx.options@`, `ctx.task@`, `ctx.board-top?@`, `ctx.view?@`, `ctx.uart-gap?@`, `ctx.blink?@`, `ctx.release?@`
- [ ] 2.3 Write test `tests/build_ctx_test.4th`: create mock project, call `build-ctx-new`, verify all fields populated correctly; run `fmix test tests/build_ctx_test.4th`
- [ ] 2.4 Update `fsoc/build.4th`: `fsoc-build` creates ctx once, passes to `task.emit`, `target.emit`, `target.run`; change signatures to `( ctx -- )`
- [ ] 2.5 Create shim for non-migrated tasks: `task-emit-shim ( project -- ) build-ctx-new swap execute` — allows gradual migration

## 3. Migrate Tasks to Context API

- [ ] 3.1 **blinky.4th**: change `blinky-emit` to `( ctx -- )`, read `ctx.project@`, `ctx.cpu@`, `ctx.platform@`, `ctx.blink?@`; remove `blinky-clk` variable; use `ctx.board-clock-io@` for clock; verify `cd projects/blinky_emul && fsoc --build`
- [ ] 3.2 **soc.4th**: change `soc-emit` to `( ctx -- )`, read all state from ctx; remove `soc-cpu`, `soc-clk`, `soc-board-top?`, `soc-view?`, `soc-board-top?` variables; use `ctx.board-clock-io@`, `ctx.board-top?@`, `ctx.view?@`; verify `cd projects/soc_emul && fsoc --build` and `cd projects/soc_terasic_de0nano && fsoc --build`
- [ ] 3.3 **cg-f.4th** / `cg-f-base.4th`: change entry points to `( ctx cpu -- )`, read `ctx.project@`, `ctx.platform@`, `ctx.blink?@`, `ctx.release?@`; remove `avr-want-blink`, `avr-want-repl` variables; verify all CG=F projects build
- [ ] 3.4 **standalone.4th**: change to context API; verify `cd projects/standalone_j1a && fsoc --build`
- [ ] 3.5 **cg-bcpu.4th**, **cg-cd16.4th**, **cg-msl16.4th**, **cg-z80.4th**: update deferred word implementations to use ctx; verify respective projects
- [ ] 3.6 Remove global variables after all consumers migrated: `soc-cpu`, `soc-clk`, `soc-board-top?`, `soc-view?`, `blinky-clk`, `avr-want-blink`, `avr-want-repl`, `target-reg-sim`, `opt-find-*`, `reg-find-*`, `find-io-*`, `plat-clock-*`, `leaf-*`, `flatten-*`, `bcpu-*`; verify `grep -r "variable.*soc-cpu\|variable.*soc-clk\|variable.*blinky-clk\|variable.*avr-want" fsoc/` returns nothing

## 4. Declarative HDL DSL (`fsoc/hdl-dsl.4th`)

- [ ] 4.1 Create `fsoc/hdl-dsl.4th` with AST structures (`dsl-design%`, `dsl-component%`, `dsl-instance%`), `hdl-design`, `end-design`, `component`, `end-component`, `instance`, `end-instance`, `param`, `connect`, `core`, `wrap`, `extra`, `include`, `ports`, `condition`, `top-name`, `src-file`; verify loads
- [ ] 4.2 Implement codegen in `end-design`: traverse components → emit `hdl-include-v`/`hdl-blackbox`/`in-port`/`out-port`; traverse instances → emit `hdl-module`/`hdl-instance`/`hdl-inst-param`/`inst-connect`/`hdl-assign` for invert; verify generates valid fhdlgen IR
- [ ] 4.3 Handle conditional components: `condition` flag false → skip component entirely; test with `hdl-no-uart?` on Colorlight
- [ ] 4.4 Handle optional connections: `connect foo bar?` where `bar?` resolves to 0 → skip connection; test with `uart_rx?` on Colorlight
- [ ] 4.5 Handle signal inversion: `connect led led (invert: LED_LOW?)` with true → emit `hdl-assign led = ~led_q`; test with `soc-led-low?`
- [ ] 4.6 Write test `tests/hdl_dsl_test.4th`: define simple design with component + instance, run codegen, capture output, compare with imperative version; run `fmix test tests/hdl_dsl_test.4th`

## 5. Migrate Designs to Declarative DSL

- [ ] 5.1 Rewrite `designs/soc_top.4th` in declarative DSL (keep old as `designs/soc_top_legacy.4th`); generate both with fhdlgen, `diff top.v` — must be identical; verify `cd projects/soc_emul && fsoc --build`
- [ ] 5.2 Rewrite `designs/blinky_top.4th` in declarative DSL; diff output; verify `cd projects/blinky_emul && fsoc --build`
- [ ] 5.3 Update `designs/lib/params.4th` to work with both DSL styles (provide `CLK_HZ?`, `BAUD?`, `TIMER_DIV?`, `LED_LOW?`, `hdl-no-uart?`, `hdl-maybe-rst-dump`, `hdl-rst-dump-connect`, `soc-kit-core`, `soc-kit-wrap`, `soc-uart-ports`, `soc-tie-wires`, `soc-uart-connect`, `soc-led-connect`, `soc-led-invert`)
- [ ] 5.4 Add `hdl-dsl.4th` to module system (Phase 1) as module `fsoc.hdl-dsl`

## 6. Integration Verification

- [ ] 6.1 Run full test suite: `fmix test` — all tests pass
- [ ] 6.2 Run linter: `flint lint . --strict --project-only` — no errors
- [ ] 6.3 Test all example projects from AGENTS.md (same list as Phase 1)
- [ ] 6.4 Verify binary output identity: for each project, build with old imperative design (via `soc_top_legacy.4th`) and new DSL design, `diff` generated `top.v` and `firmware.hex` — must be identical
- [ ] 6.5 Update `CHANGELOG.md` with Phase 2 changes
- [ ] 6.6 Run `openspec validate` on the change — no errors