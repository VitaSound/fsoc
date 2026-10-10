# fsoc Project Analysis & Improvement Recommendations

## Executive Summary

fsoc is a sophisticated **Forth-native SoC builder** (LiteX analogue) written in Gforth. It generates HDL via [fhdlgen](https://github.com/VitaSound/fhdlgen), supports 8 CPU architectures, and manages complex cross-compilation flows. The codebase demonstrates excellent Forth engineering but has several areas where structure, maintainability, and developer experience could be significantly improved.

---

## Current Architecture Assessment

### Strengths ✅

| Area | Description |
|------|-------------|
| **Core DSL** | Clean platform IR (`platform.4th`), task/target registry (`registry.4th`), manifest system (`project.4th`) |
| **Multi-CPU Support** | 8 CPU profiles (J1a/J1b/J1abs, AVR, bcpu, CD16, MSL16, Z80, mcpu) with unified CG dispatch |
| **Build Pipeline** | Declarative `--build`/`--load`/`--clean` with proper separation of concerns |
| **Testing** | Comprehensive test matrix with selective long-test execution via `pre-push.sh` |
| **Documentation** | Detailed AGENTS.md, OpenSpec specs, CPU-specific docs in `doc/` |
| **Reproducibility** | FSOC_HOME-based paths, no environment guessing, git tracks only `target.4th` |

### Structural Issues 🔴

| Issue | Impact | Location |
|-------|--------|----------|
| **No module system** | All Forth files loaded into single image; name collisions, no encapsulation | Entire `fsoc/` |
| **Stringly-typed CG dispatch** | `s" avr" compare` chains in `cg-f.4th`, `blinky-mcu-f` | `fsoc/tasks/cg-f.4th:150-180` |
| **Duplicate board mapping logic** | `blinky-map-board`, `soc-map-board`, `bcpu-map` all similar | `blinky.4th`, `soc.4th`, `cg-bcpu.4th` |
| **Hardcoded paths** | `cpu/j1/`, `rtl/`, `swapforth/` scattered in tasks | `soc.4th`, `cg-bcpu.4th`, `cg-f.4th` |
| **Global state soup** | 50+ `variable`/`2variable`/`defer` across files | `fsoc/*.4th`, `fsoc/tasks/*.4th` |
| **No type safety** | Stack effects only in comments; easy to mismatch | Everywhere |
| **Single-image testing** | Tests load full fsoc; slow, no isolation | `tests/*.4th` |
| **CG=F per-CPU duplication** | Each CPU reimplements hex generation, kernel loading | `cg-f.4th`, `cg-bcpu.4th`, `cg-cd16.4th`, `cg-msl16.4th`, `cg-z80.4th` |

---

## Detailed Improvement Recommendations

### 1. Introduce a Forth Module System

**Problem**: 150+ files loaded into one dictionary; `s" foo" find-name` lookups are fragile.

**Solution**: Lightweight module loader with explicit imports/exports.

```forth
\ fsoc/modules.4th
create module-registry ulist-new

: module: ( name-a name-u -- )  \ begin module
    current-module @ dup 0= IF 2drop ELSE true abort" nested module" THEN
    2dup fsoc-store module-name !  \ store name
    ulist-new module-exports !     \ export list
    current-module ! ;

: module-end ( -- )  \ end module, register
    current-module @ dup 0= IF true abort" no current module" THEN
    module-registry @ ulist-add
    0 current-module ! ;

: export ( xt -- )  \ add to current module's exports
    current-module @ module-exports @ ulist-add ;

: import ( module-name-a module-name-u xt-a xt-u -- )
    \ resolve export from module, bind to xt in caller
    module-registry @ ['] module-find ulist-each
    ... ;
```

**Migration**: Convert `fsoc/core.4th` includes to explicit modules:
```forth
module: fsoc.paths  export fsoc-root  export fsoc-path  export fsoc-basename  module-end
module: fsoc.registry  export task-register  export target-register  export task-find  module-end
```

### 2. Replace Stringly-Typed CG Dispatch with Protocol Tables

**Current** (`cg-f.4th:150-180`):
```forth
: cg-f ( project cpu -- )
   dup cpu.id$ @ fsoc-fetch s" avr" compare 0= if avr-hex exit then
   dup cpu.id$ @ fsoc-fetch s" bcpu" compare 0= if bcpu-soc exit then
   ...
```

**Proposed**: Protocol-based dispatch in `cpu%` structure:

```forth
begin-structure cpu%
    ...
    field: cpu.cg-hex     \ xt: project cpu -- (generate hex)
    field: cpu.cg-blinky  \ xt: project cpu -- (baremetal blink)
    field: cpu.cg-soc     \ xt: project cpu -- (soc image)
end-structure

: cpu-set-cg-f ( cpu -- )
    cpu@ cpu.cg-hex   !  \ set per-CPU
    cpu@ cpu.cg-blinky !
    cpu@ cpu.cg-soc    ! ;
```

Then in `cpu.4th` when defining each CPU:
```forth
s" avr" cpu-new
...
' avr-hex      cpu.cg-hex !
' avr-blinky   cpu.cg-blinky !
' avr-fsys     cpu.cg-soc !

s" bcpu" cpu-new
...
' bcpu-hex     cpu.cg-hex !
' bcpu-blinky  cpu.cg-blinky !
' bcpu-soc     cpu.cg-soc !
```

**Dispatch becomes**:
```forth
: cg-f ( project cpu -- )
    dup cpu.cg-hex @ execute ;  \ or cg-blinky / cg-soc based on task
```

### 3. Unify Board Pin Mapping

**Current**: Three nearly-identical functions:
- `blinky-map-board` (blinky.4th)
- `soc-map-board` (soc.4th)  
- `bcpu-map` (cg-bcpu.4th)

**Proposed**: Generic pin mapping in `platform.4th`:

```forth
\ platform.4th additions
: pin-map ( resource-name resource-index signal-name -- )
    \ request resource, map to signal in current quartus project
    2 pick 2 pick io-find dup 0= IF abort" unknown resource" THEN
    request
    s" " 2swap quartus-map  \ or quartus-map-sub for subsignals
    fjson.str-free ;

: board-map-clock ( signal-name -- )
    plat-clock io.name$ @ fsoc-fetch plat-clock io.index @ request
    s" " 2swap quartus-map fjson.str-free ;

: board-map-led ( signal-name active-low? -- )
    s" user_led" 0 io-find dup 0= IF abort" no user_led" THEN
    request
    over IF s" " 2swap quartus-map ELSE s" " 2swap quartus-map THEN
    active-low IF s" led = ~led_q" hdl-assign THEN
    fjson.str-free 2drop ;

: board-map-uart ( tx-signal rx-signal -- )
    s" serial" 0 io-find dup 0= IF 2drop EXIT THEN
    request
    2swap
    s" tx" s" uart_tx" quartus-map-sub
    s" rx" s" uart_rx" quartus-map-sub
    fjson.str-free ;
```

**Usage in tasks**:
```forth
: soc-map-board ( project -- )
    current-platform @ 0= IF drop EXIT THEN
    s" soc" quartus-project
    project.top-module@ 2dup quartus-top s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
    soc-clk-hz 1000000000 swap / fjson.u>str quartus-clock
    s" clk" board-map-clock
    s" led" false board-map-led
    soc-serial? IF s" uart_tx" s" uart_rx" board-map-uart THEN ;
```

### 4. Factor CG=F Common Infrastructure

**Current**: Each CPU duplicates:
- Kernel loading sequence
- Cross-compiler loading  
- Hex file generation
- Firmware size reporting

**Proposed**: Abstract base in `fsoc/tasks/cg-f-base.4th`:

```forth
\ cg-f-base.4th
defer cg-kernel-load     \ ( project cpu -- )
defer cg-cross-load      \ ( project cpu -- )
defer cg-extra-load      \ ( project cpu blink? -- )
defer cg-hex-file        \ ( project -- )  \ writes firmware.hex
defer cg-size-report     \ ( -- )

: cg-f-fsys ( project cpu -- )
    cg-kernel-load
    cg-cross-load
    project cg-blink? cg-extra-load
    cg-hex-file
    cg-size-report ;

: cg-f-blinky ( project cpu -- )
    cpu cg-hw-note
    s" Software" fsoc-note
    ."     image tool: fasm" cr
    s" firmware/blink_<cpu>.4th" project cg-asm-hex
    project cg-copy-leaves
    project cg-top-module
    project 0 cg-map-board
    s" Software complete" fsoc-note ;
```

Each CPU then just provides the deferred words:
```forth
\ In cg-bcpu.4th
' bcpu-kernel    is cg-kernel-load
' bcpu-cross     is cg-cross-load
' bcpu-extra     is cg-extra-load
' bcpu-hex-file  is cg-hex-file
' bcpu-bytes     is cg-size-report
' bcpu-hw        is cg-hw-note
' bcpu-asm       is cg-asm-hex
' bcpu-leaf      is cg-copy-leaves
' bcpu-top!      is cg-top-module
' bcpu-map       is cg-map-board
```

### 5. Structured Global State → Context Objects

**Current**: 50+ globals (`current-platform`, `current-io`, `soc-cpu`, `soc-clk`, `blinky-clk`, `avr-want-blink`, etc.)

**Proposed**: Pass context explicitly or use scoped variables:

```forth
\ Instead of globals, use context structs passed on stack
begin-structure build-ctx%
    field: ctx.project
    field: ctx.cpu
    field: ctx.platform
    field: ctx.target
    field: ctx.board-clock-io
    field: ctx.options
end-structure

: build-ctx-new ( project -- ctx )
    build-ctx% allocate throw >r
    r@ ctx.project !
    r@ project.cpu@ cpu-find r@ ctx.cpu !
    project board-load r@ ctx.platform !
    r@ ctx.options ulist-new !
    r> ;
```

This enables:
- Reentrant builds
- Parallel test execution
- Clear dependencies
- Easier mocking in tests

### 6. Design DSL Improvements

**Current** (`designs/soc_top.4th`): Imperative, verbose, hard to extend.

**Proposed**: Declarative component composition:

```forth
\ designs/soc_top.4th (proposed)
hdl-design soc
  top-name top
  src-file designs/soc_top.4th
  
  component j1-wrap
    core   soc-kit-core
    wrap   soc-kit-wrap
    extra  lib/j1_wrap.4th
  
  component uart
    condition hdl-no-uart? 0=
    include uart.v
    ports uart_rx in  uart_tx out
  
  component timer
    include timer.v
  
  component regio
    include regio.v
  
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

### 7. Test Architecture Overhaul

**Current**: Single-image tests, slow, `test-setup`/`test-teardown` global state.

**Proposed**: Isolated test runner with fixtures:

```forth
\ tests/runner.4th
: test-case ( name-a name-u setup-xt test-xt teardown-xt -- )
    >r >r >r
    cr ." TEST: " 2dup type cr
    r@ execute  \ setup
    r> execute  \ test
    r> execute  \ teardown
    ." PASS" cr ;

: test-suite ( name-a name-u cases-xt -- )
    ... ;

\ Usage:
: soc-build-test ( -- )
    fsoc-test-project  \ creates temp project dir
    s" blinky" task:
    s" emulation" target:
    s" --build" fsoc-dispatch
    \ verify outputs
    fsoc-test-cleanup ;
```

**Benefits**: 
- Parallel test execution
- No global state pollution
- Clear setup/teardown
- Can run single test without full suite

### 8. Configuration System

**Current**: Options via `option:` in manifest, accessed via `project.opt@`.

**Proposed**: Typed configuration with validation:

```forth
\ fsoc/config.4th
begin-structure config-spec%
    field: spec.name$
    field: spec.type      \ string | int | bool | enum
    field: spec.default
    field: spec.validate  \ xt: value -- flag
    field: spec.doc
end-structure

variable config-specs ulist-new config-specs !

: config-define ( name type default validate doc -- )
    config-spec% allocate throw >r ... r> config-specs @ ulist-add ;

: config-get ( name project -- value )
    project.opt@ dup 0= IF
        config-specs @ ['] config-find-default ulist-each
    THEN ;

\ Define configs once:
config-define s" led-bit"   s" int"   0  ['] validate-pin  s" LED pin index"
config-define s" lamp"      s" bool"  0  ['] validate-bool  s" Include lamp firmware"
config-define s" image"     s" enum"  s" debug"  ['] validate-image  s" Image type: debug|release"
config-define s" model"     s" string" 0  ['] validate-model s" MCU part (atmega8, etc.)"
```

### 9. Documentation Generation

**Current**: Manual .md files, JSON word graphs via Python script.

**Proposed**: Auto-generate from Forth source:

```forth
\ doc/generate.4th
: doc-gen-api ( -- )
    \ Scan fsoc/*.4th for : word ( -- ) \ doc-string
    \ Generate Markdown with stack effects
    
: doc-gen-cpus ( -- )
    \ Iterate cpu.4th profiles, emit comparison table
    
: doc-gen-boards ( -- )
    \ Parse boards/*.4th, emit pinout tables
    
: doc-gen-tasks ( -- )
    \ List registered tasks with their options
```

---

## Priority Implementation Roadmap

### Phase 1: Foundation (Low Risk, High Impact)
| # | Task | Effort | Files |
|---|------|--------|-------|
| 1 | Add `modules.4th` loader | 2 days | New + `fsoc/core.4th` |
| 2 | Extract `cg-f-base.4th` common CG=F logic | 3 days | `cg-f.4th`, `cg-bcpu.4th`, `cg-cd16.4th`, `cg-msl16.4th`, `cg-z80.4th` |
| 3 | Unify board mapping in `platform.4th` | 2 days | `platform.4th`, `blinky.4th`, `soc.4th`, `cg-bcpu.4th` |
| 4 | Add typed config system | 2 days | New `fsoc/config.4th` + manifest updates |

### Phase 2: Architecture (Medium Risk)
| # | Task | Effort | Files |
|---|------|--------|-------|
| 5 | Protocol-based CG dispatch in `cpu%` | 2 days | `cpu.4th`, `cg-f.4th`, `cg-i-blink.4th` |
| 6 | Context objects for build state | 3 days | `build.4th`, `project.4th`, all tasks |
| 7 | Declarative HDL design DSL | 4 days | `hdl.4th`, `designs/*.4th` |

### Phase 3: Developer Experience
| # | Task | Effort | Files |
|---|------|--------|-------|
| 8 | Isolated test runner | 3 days | `tests/runner.4th`, all `tests/*.4th` |
| 9 | Auto-documentation generator | 2 days | New `doc/generate.4th` |
| 10 | LSP/IDE support stubs | 2 days | New `fsoc/lsp.4th` |

### Phase 4: Advanced
| # | Task | Effort | Notes |
|---|------|--------|-------|
| 11 | Parallel build support | 5 days | Requires context objects (Phase 2) |
| 12 | Incremental builds | 4 days | Track file hashes, skip unchanged |
| 13 | Package manager integration | 3 days | `fmix` already exists, extend |

---

## Code Quality Metrics (Current State)

| Metric | Value | Target |
|--------|-------|--------|
| Forth files | ~150 | — |
| Total LOC (Forth) | ~15,000 | — |
| Global variables | 50+ | < 10 |
| String comparisons in dispatch | 15+ | 0 |
| Duplicate board mapping fns | 3 | 1 |
| CG=F implementations | 6 | 1 base + 6 delegates |
| Test isolation | None | Full |
| Module encapsulation | None | Complete |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing projects | Keep `target.4th` manifest format; only internal refactor |
| fhdlgen compatibility | DSL changes only in `designs/`; fhdlgen input unchanged |
| Test regression | Run `fmix test` after each phase; pre-push hook validates |
| Knowledge loss | Document patterns in `doc/architecture.md` |

---

## Conclusion

fsoc is a **remarkable piece of Forth engineering** with a clean conceptual architecture. The recommended improvements are **evolutionary, not revolutionary** — they preserve the existing manifest/contract model while introducing:
1. **Modularity** for maintainability
2. **Protocol dispatch** for extensibility  
3. **Unified infrastructure** for reduced duplication
4. **Typed configuration** for safety
5. **Isolated testing** for velocity

The Phase 1 changes alone would reduce ~2,000 LOC of duplication and eliminate the fragile string-dispatch chains, with minimal risk to existing projects.

---

*Analysis generated from codebase review on 2026-10-09. See AGENTS.md for project conventions.*