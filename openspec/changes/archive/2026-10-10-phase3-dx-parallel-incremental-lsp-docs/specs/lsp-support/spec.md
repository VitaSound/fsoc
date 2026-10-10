# Spec Delta

## Purpose

Provides Language Server Protocol (LSP) support for Gforth/fsoc, enabling go-to-definition, hover (stack effect), and completion in editors (VS Code, vim, emacs).

## ADDED Requirements

### Requirement: LSP server entry point
The system SHALL provide `fsoc/lsp.4th` runnable as `gforth fsoc/lsp.4th` speaking JSON-RPC 2.0 on stdio.

#### Scenario: Server starts
- **WHEN** editor launches `gforth fsoc/lsp.4th`
- **THEN** server responds to `initialize` with capabilities: `textDocumentSync`, `hoverProvider`, `definitionProvider`, `completionProvider`

### Requirement: Go-to-definition
The system SHALL resolve `textDocument/definition` for Forth words: find the file and line where `:` or `defer` or `variable` or `create` defines the word.

#### Scenario: Jump to task definition
- [ ] **WHEN** cursor on `blinky-emit` in `blinky.4th`
- [ ] **THEN** LSP returns location `fsoc/tasks/blinky.4th:42`

#### Scenario: Jump to variable
- [ ] **WHEN** cursor on `fsoc-tasks`
- [ ] **THEN** LSP returns `fsoc/registry.4th:15`

#### Scenario: Jump to board pin
- [ ] **WHEN** cursor on `user_led` in board file
- [ ] **THEN** LSP returns `boards/terasic_de0nano.4th:12`

### Requirement: Hover with stack effect
The system SHALL provide `textDocument/hover` showing stack effect and description from source comment.

#### Scenario: Hover on word
- [ ] **WHEN** hover on `fsoc-path`
- [ ] **THEN** tooltip: `fsoc-path ( rel-a rel-u -- abs-a abs-u ) — Convert relative to absolute path using FSOC_HOME`

#### Scenario: Hover on CPU profile
- [ ] **WHEN** hover on `j1a` in `cpu.4th`
- [ ] **THEN** tooltip shows CPU profile fields: Class=0, FMAP=V-V-A-0-I, CG=I, Width=32, etc.

### Requirement: Completion
The system SHALL provide `textDocument/completion` for:
- Registered task names (`blinky`, `soc`, `standalone`)
- Target names (`emulation`, `quartus`, `yosys`, `proteus`)
- CPU IDs (`j1a`, `j1b`, `j1abs`, `avr`, `bcpu`, `cd16`, `msl16`, `z80`, `stm8`)
- Board names (`colorlight_5a_75e_v6_0`, `terasic_de0nano`, `ep2c5_mini`, `lfe5u25f_cabga256`)
- Option names (`led-bit`, `lamp`, `image`, `model`)
- Forth words in current scope (locals, globals, module exports)

#### Scenario: Complete task name
- [ ] **WHEN** typing `s" blink` in `target.4th`
- [ ] **THEN** completion suggests `blinky`

#### Scenario: Complete option
- [ ] **WHEN** typing `s" led` in `target.4th`
- [ ] **THEN** completion suggests `led-bit`

### Requirement: Index generation
The system SHALL build an in-memory index on startup by scanning `FSOC_HOME/fsoc/**/*.4th`, `FSOC_HOME/boards/*.4th`, `FSOC_HOME/designs/*.4th`, `FSOC_HOME/cpu/**/*.4th`, `FSOC_HOME/fsys/**/*.4th`, `FSOC_HOME/targets/*.4th`, `FSOC_HOME/projects/**/target.4th`.

#### Scenario: Index built on startup
- [ ] **WHEN** LSP server starts
- [ ] **THEN** scans all .4th files, builds symbol table in < 2s for full repo

### Requirement: Configuration
The system SHALL read `FSOC_HOME` from environment; support `fsoc.lsp.indexPath` config for custom index location.

#### Scenario: Custom FSOC_HOME
- [ ] **WHEN** editor config has `"fsoc.lsp.fsocHome": "/custom/path"`
- [ ] **THEN** server indexes that path instead of env var