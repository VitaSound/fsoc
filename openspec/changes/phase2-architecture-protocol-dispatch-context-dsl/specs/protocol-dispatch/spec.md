# Spec Delta

## Purpose

Replaces string-based CG dispatch (`s" avr" compare` chains) with function pointers in `cpu%` structure, enabling O(1) dispatch and open extensibility for new CG codes.

## ADDED Requirements

### Requirement: CG function pointers in cpu%
The system SHALL add function pointer fields to `cpu%` for each CG entry point: `cpu.cg-hex`, `cpu.cg-blinky`, `cpu.cg-soc`, `cpu.cg-i-blink`, `cpu.cg-halt`.

#### Scenario: CPU profile sets CG function pointers
- **WHEN** CPU profile registration executes `' avr-hex cpu.cg-hex !` etc.
- **THEN** `cpu.cg-hex @` returns the xt for AVR hex generation

#### Scenario: Missing function pointer
- **WHEN** CPU profile has CG=F but `cpu.cg-hex @` is 0
- **THEN** system aborts with "cpu <id>: missing cg-hex function pointer" at dispatch

### Requirement: O(1) dispatch via function pointers
The system SHALL dispatch CG entry points by executing the function pointer from `cpu%`, not by string comparison.

#### Scenario: cg-f dispatch
- **WHEN** `cg-f` called with project and cpu
- **THEN** executes `cpu.cg-hex @ execute` (or `cg-blinky`/`cg-soc` based on task)

#### Scenario: cg-i-blink dispatch
- **WHEN** `cg-i-blink` called with project and cpu
- **THEN** executes `cpu.cg-i-blink @ execute`

#### Scenario: soc task CG dispatch
- **WHEN** `soc-emit` calls `cg-run`
- **THEN** executes `cpu.cg$ @ fsoc-fetch cg-find cg.emit @ execute` (existing) OR new `cpu.cg-soc @ execute` for CG=I/F

### Requirement: Backward compatibility for CG=E
The system SHALL retain `cg-halt` for CG=E (no hex image) via function pointer.

#### Scenario: STM8 CG=E dispatch
- **WHEN** `cg-run` with STM8 cpu (CG=E)
- **THEN** executes `cpu.cg-halt @ execute` → "has no hex image" abort

### Requirement: New CG codes register function pointers
The system SHALL allow new CG codes by adding function pointer fields to `cpu%` and registering emitters without modifying dispatch logic.

#### Scenario: Add CG=X for new CPU
- **WHEN** new CPU profile adds `cpu.cg-x` field and sets it
- **THEN** dispatch works without changing `cg-f.4th`, `cg-i-blink.4th`, `soc.4th`