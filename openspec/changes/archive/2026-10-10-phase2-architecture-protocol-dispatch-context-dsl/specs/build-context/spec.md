# Spec Delta

## Purpose

Replaces 50+ global variables with a scoped `build-ctx%` structure passed on the stack, enabling reentrant builds, isolated testing, and clear data dependencies.

## ADDED Requirements

### Requirement: Build context structure
The system SHALL define `build-ctx%` with fields for all build-time state currently in globals.

#### Scenario: Context contains project reference
- **WHEN** `build-ctx-new` creates context from project
- **THEN** `ctx.project @` returns the project

#### Scenario: Context contains resolved CPU
- **WHEN** `build-ctx-new` resolves `project.cpu@ cpu-find`
- **THEN** `ctx.cpu @` returns the cpu structure

#### Scenario: Context contains platform
- **WHEN** `build-ctx-new` loads board via `board-load`
- **THEN** `ctx.platform @` returns the platform structure

#### Scenario: Context contains target
- **WHEN** `build-ctx-new` resolves `project.target@ target-find`
- **THEN** `ctx.target @` returns the target structure

#### Scenario: Context contains board clock IO
- **WHEN** platform has clock resource
- **THEN** `ctx.board-clock-io @` returns the clock IO structure

#### Scenario: Context contains options map
- **WHEN** `build-ctx-new` copies `project.opts` to context
- **THEN** `ctx.options @` returns ulist with option name→value mappings

### Requirement: Context-passing API
The system SHALL update all task emit functions to accept `( ctx -- )` instead of reading globals.

#### Scenario: blinky-emit uses context
- **WHEN** `blinky-emit` called with ctx
- **THEN** reads `ctx.project @`, `ctx.cpu @`, `ctx.platform @` instead of globals

#### Scenario: soc-emit uses context
- **WHEN** `soc-emit` called with ctx
- **THEN** reads all needed state from ctx; no global `soc-cpu`, `soc-clk`, `soc-board-top?`, `soc-view?`

#### Scenario: cg-f base uses context
- **WHEN** `cg-f-fsys` called with ctx and cpu
- **THEN** reads `ctx.project @`, `ctx.platform @`; no global `avr-want-blink`, `avr-want-repl`

### Requirement: Global variable elimination
The system SHALL remove or deprecate global variables replaced by context fields.

#### Scenario: soc-cpu removed
- **WHEN** `soc-cpu` variable accessed
- **THEN** replaced by `ctx.cpu @` — variable removed from `soc.4th`

#### Scenario: soc-clk removed
- **WHEN** `soc-clk` variable accessed
- **THEN** replaced by `ctx.board-clock-io @` — variable removed

#### Scenario: blinky-clk removed
- **WHEN** `blinky-clk` variable accessed
- **THEN** replaced by `ctx.board-clock-io @` — variable removed

#### Scenario: avr-want-* removed
- **WHEN** `avr-want-blink`, `avr-want-repl` accessed
- **THEN** replaced by `ctx.options @` lookup — variables removed from `cg-f.4th`

#### Scenario: Registry globals remain (acceptable)
- **WHEN** `fsoc-tasks`, `fsoc-targets`, `fsoc-cpus`, `fsoc-cgs`, `fsoc-kits` accessed
- **THEN** these remain as global registries (singletons, not build-state)

### Requirement: Context lifecycle
The system SHALL create context once per build in `fsoc-build`, pass it through task.emit → target.emit → target.run.

#### Scenario: Single context per build
- **WHEN** `fsoc-build` executes
- **THEN** `build-ctx-new` called once, same ctx passed to all three phases

#### Scenario: Context not leaked
- **WHEN** build completes
- **THEN** no context references remain in globals