# Spec Delta

## Purpose

Provides a declarative HDL design syntax (`hdl-design`, `component`, `instance`, `connect`, `param`) as an alternative to the imperative fhdlgen API, improving readability and enabling composition.

## ADDED Requirements

### Requirement: Design declaration
The system SHALL provide `hdl-design ( name -- )` ... `end-design` words that create a design container.

#### Scenario: Declare SOC design
- **WHEN** `hdl-design soc  ...  end-design` executes
- **THEN** design named "soc" registered with empty component/instance lists

### Requirement: Component declaration
The system SHALL provide `component ( name -- )` ... `end-component` for reusable hardware blocks.

#### Scenario: Declare J1 wrap component
- **WHEN** `component j1-wrap  core soc-kit-core  wrap soc-kit-wrap  extra lib/j1_wrap.4th  end-component` executes
- **THEN** component "j1-wrap" registered with core, wrap, extra file references

#### Scenario: Component with conditional inclusion
- **WHEN** `component uart  condition hdl-no-uart? 0=  include uart.v  ports uart_rx in uart_tx out  end-component` executes
- **THEN** component "uart" registered with condition and port declarations

### Requirement: Instance declaration with connections
The system SHALL provide `instance ( inst-name comp-name -- )` ... `end-instance` for instantiating components with port connections and parameters.

#### Scenario: Instantiate top with parameters and connections
- **WHEN** `instance top j1-wrap  param USE_TIMER 1  param USE_REGIO 1  connect clk clk  connect rst rst_dump?  connect uart_rx uart_rx?  connect uart_tx uart_tx?  connect led led (invert: LED_LOW?)  end-instance` executes
- **THEN** instance "top" of component "j1-wrap" registered with params and connections

#### Scenario: Optional connections
- **WHEN** `connect uart_rx uart_rx?` where `uart_rx?` resolves to 0 (condition false)
- **THEN** connection omitted from generated fhdlgen IR

#### Scenario: Signal inversion in connection
- **WHEN** `connect led led (invert: LED_LOW?)` with `LED_LOW?` true
- **THEN** generated IR includes `hdl-assign` `led = ~led_q`

### Requirement: Parameter declaration
The system SHALL provide `param ( name value -- )` inside instance for fhdlgen `--param` passthrough.

#### Scenario: Instance parameters passed to fhdlgen
- **WHEN** `param CLK_HZ CLK_HZ?` where `CLK_HZ?` resolves to 50000000
- **THEN** fhdlgen receives `--param CLK_HZ=50000000`

### Requirement: Backward compatibility shim
The system SHALL keep existing imperative API (`hdl-project`, `hdl-module`, `hdl-instance`, `in-port`, `out-port`, `inst-connect`, `hdl-include-v`, `hdl-blackbox`, `hdl-assign`) working unchanged.

#### Scenario: Existing designs/blinky_top.4th works unchanged
- **WHEN** `gforth designs/blinky_top.4th` loads
- **THEN** generates same `top.v` as before

#### Scenario: New declarative design generates same output
- **WHEN** `designs/soc_top.4th` rewritten in declarative style
- **THEN** `fhdlgen build designs/soc_top.4th --out /tmp` produces identical `top.v`

### Requirement: DSL implementation in separate file
The system SHALL implement DSL in `fsoc/hdl-dsl.4th`, loaded by `fsoc/hdl.4th` or directly by designs.

#### Scenario: Load hdl-dsl.4th
- **WHEN** `s" fsoc/hdl-dsl.4th" included`
- **THEN** all DSL words available, no conflicts with existing `hdl.4th` words