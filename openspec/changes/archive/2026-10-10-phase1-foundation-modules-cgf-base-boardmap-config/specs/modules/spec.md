# Spec Delta

## Purpose

Provides a lightweight module system for Forth with explicit imports/exports, name isolation, and deterministic load order, replacing the monolithic `included`-based loading.

## ADDED Requirements

### Requirement: Module declaration and registration
The system SHALL provide words to declare a module, define its exports, and register it in a global module registry.

#### Scenario: Declare a module with exports
- **WHEN** user writes `module: foo.4th  export foo-bar  export foo-baz  module-end`
- **THEN** module `foo.4th` is registered with exports `foo-bar` and `foo-baz` accessible via `import`

#### Scenario: Module without exports
- **WHEN** user writes `module: bar.4th  module-end`
- **THEN** module `bar.4th` is registered with empty export list

### Requirement: Import resolution
The system SHALL resolve imports by finding the exported xt from the target module and binding it to the requested name in the importing module's namespace.

#### Scenario: Import a single word
- **WHEN** user writes `import foo.4th  foo-bar  my-bar`
- **THEN** `my-bar` executes the same xt as `foo-bar` from module `foo.4th`

#### Scenario: Import multiple words
- **WHEN** user writes `import foo.4th  foo-bar  my-bar  foo-baz  my-baz`
- **THEN** both `my-bar` and `my-baz` are bound to respective exports

#### Scenario: Import from non-existent module
- **WHEN** user writes `import missing.4th  foo-bar  my-bar`
- **THEN** system aborts with clear error "module not found: missing.4th"

#### Scenario: Import non-exported word
- **WHEN** user writes `import foo.4th  private-word  my-word`
- **THEN** system aborts with clear error "not exported: private-word"

### Requirement: Load order and dependencies
The system SHALL load modules in dependency order — a module's imports are loaded before the module itself.

#### Scenario: Transitive dependency load
- **WHEN** module `a.4th` imports `b.4th`, and `b.4th` imports `c.4th`
- **THEN** load order is `c.4th`, `b.4th`, `a.4th`

#### Scenario: Circular dependency detection
- **WHEN** module `a.4th` imports `b.4th` and `b.4th` imports `a.4th`
- **THEN** system aborts with "circular dependency detected"

### Requirement: Backward compatibility with included
The system SHALL allow gradual migration — existing `included` files work unchanged, and modules can `included` legacy files internally.

#### Scenario: Module includes legacy file
- **WHEN** module `new.4th` contains `s" legacy.4th" included`
- **THEN** `legacy.4th` loads normally, its definitions enter `new.4th`'s namespace

#### Scenario: Legacy file includes module
- **WHEN** legacy file contains `import new.4th  new-word  my-word`
- **THEN** import resolves correctly