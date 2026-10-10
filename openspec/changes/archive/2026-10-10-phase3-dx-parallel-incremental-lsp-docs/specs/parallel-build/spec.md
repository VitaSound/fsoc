# Spec Delta

## Purpose

Enables parallel execution of independent build tasks and targets using a worker pool with isolated build contexts, reducing wall-clock time for multi-project builds.

## ADDED Requirements

### Requirement: Worker pool with configurable concurrency
The system SHALL provide `--jobs N` (or `-j N`) CLI flag to set worker pool size, defaulting to CPU core count.

#### Scenario: Build with 4 workers
- **WHEN** `fsoc --build --jobs 4` executed in project with multiple independent tasks
- **THEN** up to 4 builds run concurrently

#### Scenario: Default jobs
- **WHEN** `fsoc --build` without `--jobs`
- **THEN** worker count = number of CPU cores (via `nproc` or `sysconf`)

### Requirement: Isolated build contexts per worker
The system SHALL give each worker its own `build-ctx` copy; no shared mutable state between workers.

#### Scenario: Two workers build different tasks
- **WHEN** worker 1 builds `blinky` for emulation, worker 2 builds `soc` for quartus
- **THEN** each has independent `ctx.platform`, `ctx.options`, `ctx.cpu`; no cross-contamination

#### Scenario: Worker modifies context
- **WHEN** worker sets `ctx.board-top?@` true
- **THEN** other workers' contexts unchanged

### Requirement: Task/target dependency graph
The system SHALL analyse manifest `target.4th` to build dependency graph: tasks with same design can share fhdlgen output; different boards need separate quartus runs.

#### Scenario: Shared design, different targets
- **WHEN** `soc_emul` and `soc_terasic_de0nano` share `design: soc_top.4th`
- **THEN** fhdlgen runs once, output reused; quartus runs separately per board

#### Scenario: Independent tasks
- **WHEN** `blinky_emul` and `soc_emul` in same invocation
- **THEN** run fully in parallel (different designs)

### Requirement: File-based locking for shared outputs
The system SHALL use flock(1) or equivalent on output directories to prevent concurrent writes to same artefact.

#### Scenario: Two workers write same top.v
- **WHEN** both need `projects/.../top.v`
- **THEN** second worker waits for lock, sees file exists and is fresh, skips generation

### Requirement: Progress reporting
The system SHALL report which worker builds which project, with timestamps.

#### Scenario: Verbose parallel build
- **WHEN** `fsoc --build --jobs 4 --verbose`
- **THEN** output shows `[worker 1] blinky_emul: fhdlgen...`, `[worker 2] soc_emul: cross...` interleaved but tagged