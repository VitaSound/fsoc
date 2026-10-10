# Spec Delta

## Purpose

Provides a unified, declarative API for mapping board resources (clock, LED, UART, buttons) to top-level HDL signals, replacing per-task ad-hoc mapping functions.

## ADDED Requirements

### Requirement: Clock mapping
The system SHALL provide `board-map-clock ( signal-name -- )` that requests the platform's clock resource and maps it to the given signal name in the current Quartus project.

#### Scenario: Map clock to clk signal
- **WHEN** `s" clk" board-map-clock` executes with platform loaded
- **THEN** clock resource requested, `quartus-clock` set from its frequency, `quartus-map` connects clock pin to `clk`

#### Scenario: Clock mapping without platform
- **WHEN** `board-map-clock` executes with no current platform
- **THEN** word exits silently (no-op for emulation targets)

#### Scenario: Missing clock resource
- **WHEN** platform has no clock resource with `clock-hz` set
- **THEN** system aborts with "board clock count" (existing behaviour)

### Requirement: LED mapping with active-low support
The system SHALL provide `board-map-led ( signal-name active-low? -- )` that requests `user_led` resource index 0, maps it to the signal, and optionally emits an inversion assignment.

#### Scenario: Map LED active-high
- **WHEN** `s" led" false board-map-led` executes
- **THEN** `user_led` requested, mapped to `led`, no inversion assignment

#### Scenario: Map LED active-low
- **WHEN** `s" led" true board-map-led` executes
- **THEN** `user_led` requested, mapped to `led`, `hdl-assign` emits `led = ~led_q`

#### Scenario: Missing user_led resource
- **WHEN** platform has no `user_led` index 0
- **THEN** system aborts with "request: unknown resource"

### Requirement: UART mapping with sub-signals
The system SHALL provide `board-map-uart ( tx-signal rx-signal -- )` that requests `serial` resource index 0 and maps its `tx`/`rx` sub-signals to the given signal names.

#### Scenario: Map UART with custom signal names
- **WHEN** `s" uart_tx" s" uart_rx" board-map-uart` executes
- **THEN** `serial` requested, `quartus-map-sub` connects `tx`→`uart_tx`, `rx`→`uart_rx`

#### Scenario: UART mapping without serial resource
- **WHEN** platform has no `serial` resource
- **THEN** word exits silently (no-op, e.g. Colorlight shares pins)

### Requirement: Generic pin mapping
The system SHALL provide `pin-map ( resource-name resource-index signal-name -- )` for arbitrary resource mapping.

#### Scenario: Map button to btn signal
- **WHEN** `s" user_btn" 0 s" btn" pin-map` executes
- **THEN** `user_btn` index 0 requested, mapped to `btn`

### Requirement: Task migration
The system SHALL allow `blinky.4th`, `soc.4th`, `cg-bcpu.4th` to replace their private mapping functions with calls to the unified API without behaviour change.

#### Scenario: blinky uses unified mapping
- **WHEN** `blinky-map-board` replaced with `board-map-clock` + `board-map-led`
- **THEN** generated Quartus project identical (same pin assignments, same clock period)

#### Scenario: soc uses unified mapping
- **WHEN** `soc-map-board` replaced with `board-map-clock` + `board-map-led` + `board-map-uart`
- **THEN** generated Quartus project identical

#### Scenario: bcpu uses unified mapping
- **WHEN** `bcpu-map` replaced with `board-map-clock` + `board-map-led` + optional `pin-map` for button
- **THEN** generated Quartus project identical