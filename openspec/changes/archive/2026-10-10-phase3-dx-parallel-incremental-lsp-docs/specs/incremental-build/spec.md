# Spec Delta

## Purpose

Skips rebuild steps when inputs haven't changed, using content-addressed cache keyed by SHA256 of all source files and configuration.

## ADDED Requirements

### Requirement: Input hash computation
The system SHALL compute a deterministic SHA256 hash of all files influencing a build step: `target.4th`, board file, design file, CPU profile, kernel sources, firmware sources, fhdlgen version, toolchain versions.

#### Scenario: Hash includes all sources
- **WHEN** computing hash for `soc_emul` fhdlgen step
- **THEN** hash covers `target.4th`, `boards/colorlight_5a_75e_v6_0.4th`, `designs/soc_top.4th`, `fsoc/cpu.4th` (j1a profile), `fsys/kernel/j1a/kernel.4th`, `fhdlgen` binary hash

#### Scenario: Hash excludes build outputs
- **WHEN** computing hash
- **THEN** `projects/soc_emul/top.v`, `firmware.hex`, `sim.sh` NOT included

### Requirement: Cache storage and lookup
The system SHALL store step outputs in `.fsoc-cache/<hash>/` with manifest of produced files; on rebuild, lookup hash, if found and files exist → copy from cache.

#### Scenario: Cache hit
- **WHEN** second `fsoc --build` with no changes
- **THEN** fhdlgen, cross-compile, hex gen all skipped; outputs copied from cache; total time < 10% of clean build

#### Scenario: Cache miss
- **WHEN** `target.4th` changed `cpu: j1b`
- **THEN** hash differs, cache miss, full rebuild executed, new cache entry created

### Requirement: Incremental flag
The system SHALL provide `--no-incremental` flag to force clean rebuild ignoring cache.

#### Scenario: Force rebuild
- **WHEN** `fsoc --build --no-incremental`
- **THEN** cache not consulted, all steps run, cache updated

### Requirement: Cache invalidation on toolchain change
The system SHALL include fhdlgen version, Gforth version, Verilator version, Quartus version in hash; version change → cache miss.

#### Scenario: fhdlgen upgraded
- **WHEN** `fhdlgen --version` returns new version
- **THEN** next build cache miss, fhdlgen step re-runs

### Requirement: Cache directory management
The system SHALL store cache in `.fsoc-cache/` in project directory; `fsoc --clean` removes cache; total cache size bounded (configurable, default 1GB) with LRU eviction.

#### Scenario: Clean removes cache
- **WHEN** `fsoc --clean`
- **THEN** `.fsoc-cache/` deleted

#### Scenario: LRU eviction
- **WHEN** cache exceeds 1GB
- **THEN** oldest unused entries removed until under limit