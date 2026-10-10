# Spec Delta

## Purpose

Provides a typed configuration schema with validation, defaults, and documentation, replacing untyped `option:` / `project.opt@` with declarative `config-define` and `config-get`.

## ADDED Requirements

### Requirement: Configuration definition with types
The system SHALL provide `config-define ( name type default validate doc -- )` supporting types: `string`, `int`, `bool`, `enum`.

#### Scenario: Define string config
- **WHEN** `config-define s" model" s" string" 0 ['] validate-model s" MCU part"` executes
- **THEN** config `model` registered with string type, no default, custom validator

#### Scenario: Define int config with default
- **WHEN** `config-define s" led-bit" s" int" 0 ['] validate-pin s" LED pin index"` executes
- **THEN** config `led-bit` registered with int type, default 0, pin validator

#### Scenario: Define bool config
- **WHEN** `config-define s" lamp" s" bool" 0 ['] validate-bool s" Include lamp firmware"` executes
- **THEN** config `lamp` registered with bool type, default false

#### Scenario: Define enum config
- **WHEN** `config-define s" image" s" enum" s" debug" ['] validate-image s" Image type"` executes
- **THEN** config `image` registered with enum type, default `debug`, validator checks `debug`|`release`

### Requirement: Configuration retrieval with defaults
The system SHALL provide `config-get ( name project -- value )` that returns the project's option value or the registered default.

#### Scenario: Get value from project option
- **WHEN** project has `option: led-bit 5` and `config-get s" led-bit" project` executes
- **THEN** returns `5` (as string for int type)

#### Scenario: Get default when option absent
- **WHEN** project has no `led-bit` option and `config-get s" led-bit" project` executes
- **THEN** returns `0` (default from definition)

#### Scenario: Get bool as flag
- **WHEN** project has `option: lamp 1` and `config-get s" lamp" project` executes
- **THEN** returns `1` (true)

#### Scenario: Get enum value
- **WHEN** project has `option: image release` and `config-get s" image" project` executes
- **THEN** returns `release`

### Requirement: Validation on retrieval
The system SHALL run the registered validator when retrieving a value; invalid values abort with descriptive message.

#### Scenario: Valid pin number
- **WHEN** `config-get s" led-bit" project` with value `3` and pin validator
- **THEN** returns `3`

#### Scenario: Invalid pin number
- **WHEN** `config-get s" led-bit" project` with value `99` and pin validator
- **THEN** aborts "config 'led-bit': pin 99 out of range"

#### Scenario: Invalid enum value
- **WHEN** `config-get s" image" project` with value `production` and image validator
- **THEN** aborts "config 'image': must be debug|release"

### Requirement: Migration from option:
The system SHALL allow existing `option:` manifests to work unchanged — `config-get` reads the same `project.opts` ulist.

#### Scenario: Existing manifest with option:
- **WHEN** project has `option: lamp 1` and `config-get s" lamp" project` executes
- **THEN** returns `1` (bool true)

#### Scenario: Mixed option: and config-define
- **WHEN** some configs defined via `config-define`, others only via `option:`
- **THEN** `config-get` works for both; undefined configs return default or 0 0

### Requirement: Documentation generation
The system SHALL expose config metadata (name, type, default, doc) for auto-generated help.

#### Scenario: List all configs with docs
- **WHEN** iterating config registry
- **THEN** each entry provides name, type, default, doc string