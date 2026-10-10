# Spec Delta

## Purpose

Provides a common protocol for CG=F (hex image generation) that factors out shared kernel loading, cross-compilation, extra layers, HEX generation, and size reporting, letting each CPU supply only CPU-specific deferred words.

## ADDED Requirements

### Requirement: Common CG=F entry points
The system SHALL provide three standard entry points: `cg-f-fsys` (Soc fsys image), `cg-f-blinky` (baremetal blink), `cg-f-hex` (generic hex generation), each accepting `( project cpu -- )`.

#### Scenario: Soc fsys image generation
- **WHEN** task calls `cg-f-fsys` with project and cpu
- **THEN** sequence executes: kernel load → cross load → extra layers (blink-aware) → HEX file write → size report

#### Scenario: Baremetal blinky generation
- **WHEN** task calls `cg-f-blinky` with project and cpu
- **THEN** sequence executes: hardware note → firmware compile → HEX write → size report → leaf copy → top module → board map

#### Scenario: Generic hex generation
- **WHEN** task calls `cg-f-hex` with project and cpu
- **THEN** sequence executes: kernel load → cross load → extra layers → HEX write → size report

### Requirement: CPU-specific deferred protocol
The system SHALL define a fixed set of deferred words that each CPU MUST implement to plug into the common flow.

#### Scenario: CPU provides all required deferred words
- **WHEN** CPU profile sets `cg-kernel-load`, `cg-cross-load`, `cg-extra-load`, `cg-hex-file`, `cg-size-report`, `cg-hw-note`, `cg-asm-hex`, `cg-copy-leaves`, `cg-top-module`, `cg-map-board`
- **THEN** common entry points execute without modification

#### Scenario: Missing deferred word
- **WHEN** CPU profile omits any required deferred word
- **THEN** system aborts with "deferred word not set: <name>" at first use

### Requirement: Blink-aware extra layer loading
The system SHALL pass the project's `blink` option to `cg-extra-load` so CPU can conditionally include blink firmware.

#### Scenario: Extra load with blink=1
- **WHEN** `cg-extra-load` called with `blink? = true`
- **THEN** CPU includes blink firmware and patches boot vector

#### Scenario: Extra load without blink
- **WHEN** `cg-extra-load` called with `blink? = false`
- **THEN** CPU loads only console/repl layers

### Requirement: Hex file format abstraction
The system SHALL NOT assume Intel HEX — `cg-hex-file` is CPU-defined (Intel HEX for AVR, word hex for bcpu/CD16/MSL16/Z80).

#### Scenario: AVR produces Intel HEX
- **WHEN** AVR's `cg-hex-file` executes
- **THEN** `firmware.hex` contains Intel HEX records

#### Scenario: bcpu produces word hex
- **WHEN** bcpu's `cg-hex-file` executes
- **THEN** `firmware.hex` contains 4-digit hex words, one per line

### Requirement: Size report standardization
The system SHALL produce a consistent size report line: `firmware.hex: <N> bytes of <capacity>` for byte-addressed, or `firmware.hex: <N> bytes of <capacity>` for word-addressed (capacity in bytes).

#### Scenario: Size report for AVR
- **WHEN** AVR's `cg-size-report` executes
- **THEN** output: `firmware.hex: 1234 bytes of 8192` (flash bytes)

#### Scenario: Size report for bcpu
- **WHEN** bcpu's `cg-size-report` executes
- **THEN** output: `firmware.hex: 4096 bytes of 16384` (RAM bytes)