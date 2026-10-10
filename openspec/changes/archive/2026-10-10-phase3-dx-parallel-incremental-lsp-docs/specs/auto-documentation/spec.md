# Spec Delta

## Purpose

Generates up-to-date Markdown documentation from Forth source code: API reference with stack effects, CPU comparison tables, board pinout tables, task/target/option reference.

## ADDED Requirements

### Requirement: Stack effect extraction
The system SHALL parse Forth files for words with stack effect comments: `\ word-name ( before -- after )  Description` and extract name, stack effect, description.

#### Scenario: Extract word signature
- **WHEN** source contains `: fsoc-path ( rel-a rel-u -- abs-a abs-u )  Convert relative to absolute path`
- **THEN** extracted: name=`fsoc-path`, before=`rel-a rel-u`, after=`abs-a abs-u`, desc=`Convert relative to absolute path`

#### Scenario: Skip words without stack effect comment
- **WHEN** word has no preceding `\ name ( -- )` comment
- **THEN** not included in API reference (or included with `?` stack effect)

### Requirement: Module/namespace organisation
The system SHALL group extracted words by source file/module: `fsoc.paths`, `fsoc.registry`, `fsoc.platform`, `fsoc.tasks.blinky`, etc.

#### Scenario: API reference structure
- **WHEN** generating `doc/api/fsoc.paths.md`
- **THEN** contains table of all words from `fsoc/paths.4th` with stack effects and descriptions

### Requirement: CPU comparison table
The system SHALL generate `doc/cpu-comparison.md` from `cpu.4th` profiles: table with columns CPU, Class, FMAP, MM, EX-C, CG, BM, Width, DSP, RSP, Ref, Note.

#### Scenario: Table includes all registered CPUs
- **WHEN** `doc/generate.4th` runs
- **THEN** table has rows for j1a, j1abs, j1b, stm8, z80, avr, bcpu, cd16, msl16, mcpu

### Requirement: Board pinout tables
The system SHALL generate `doc/boards/<board>.md` from `boards/<board>.4th`: table with Resource, Index, Pins, IOStandard, Misc, ClockHz, ActiveLow, Subsignals.

#### Scenario: Colorlight board doc
- **WHEN** parsing `boards/colorlight_5a_75e_v6_0.4th`
- **THEN** table rows: clk25 (P6, LVCMOS33, 25MHz), user_led (T6, LVCMOS33, active-low), user_btn (R7, LVCMOS33)

### Requirement: Task/Target/Option reference
The system SHALL generate `doc/tasks.md`, `doc/targets.md`, `doc/options.md` from registry at runtime: iterate registered tasks/targets, extract their options via `config-specs`.

#### Scenario: Tasks reference
- **WHEN** generating `doc/tasks.md`
- **THEN** lists blinky, soc, standalone with their options (led-bit, lamp, image, model, etc.)

### Requirement: Generation command
The system SHALL provide `doc/generate.4th` runnable via `gforth doc/generate.4th` or `fsoc doc-gen`; outputs to `doc/generated/`.

#### Scenario: Full doc generation
- **WHEN** `gforth doc/generate.4th`
- **THEN** creates `doc/generated/api/`, `doc/generated/cpu-comparison.md`, `doc/generated/boards/`, `doc/generated/tasks.md`, `doc/generated/targets.md`, `doc/generated/options.md`