# Spec Delta

## Purpose

Runs each test in an isolated Gforth process with a temporary project directory, enabling parallel test execution and eliminating global state pollution.

## ADDED Requirements

### Requirement: Per-test process isolation
The system SHALL spawn a new Gforth process for each test file, passing test name and temporary project path as arguments.

#### Scenario: Test runs in clean process
- **WHEN** `fmix test tests/soc_test.4th`
- **THEN** Gforth starts, loads only `tests/soc_test.4th` and its deps, no other test's definitions present

#### Scenario: Parallel test execution
- **WHEN** `fmix test --jobs 4`
- **THEN** up to 4 Gforth processes run simultaneously, each with own temp directory

### Requirement: Temporary project sandbox
The system SHALL create a unique temporary directory per test, populate with minimal `target.4th` and required fixtures, clean up after.

#### Scenario: Test gets clean project dir
- **WHEN** `soc_test.4th` runs
- **THEN** temp dir contains `target.4th` with `task: soc`, `target: emulation`, `design: soc_top.4th`, `cpu: j1a`

#### Scenario: Fixtures copied not shared
- **WHEN** test uses `tests/fixture.4th`
- **THEN** fixture creates fresh files in test's temp dir, not in shared `projects/`

### Requirement: Test discovery and filtering
The system SHALL discover tests by scanning `tests/*.4th` (excluding `_test.4th` fixtures), support `--filter` regex to run subset.

#### Scenario: Run single test
- **WHEN** `fmix test tests/blinky_test.4th`
- **THEN** only that test executes

#### Scenario: Filter by pattern
- [ ] `fmix test --filter "blinky|soc"`
- [ ] runs only blinky and soc tests

### Requirement: Result aggregation
The system SHALL collect pass/fail/skip counts from each process, print summary, exit non-zero on any failure.

#### Scenario: Summary output
- **WHEN** `fmix test` completes
- **THEN** output: `Ran 42 tests: 40 passed, 2 skipped, 0 failed in 12.3s`

### Requirement: Backward compatibility
The system SHALL support running tests via `gforth tests/<name>.4th` directly (for debugging), with same isolation via env var `FSOC_TEST_ISOLATED=1`.

#### Scenario: Direct gforth run
- **WHEN** `FSOC_TEST_ISOLATED=1 gforth tests/soc_test.4th`
- **THEN** test sets up own temp dir, runs, cleans up