## ADDED Requirements

### Requirement: Dual micro-core ping-pong

The system SHALL provide a buildable dual-micro-core example with two MCPU instances, two different firmware images, and a shared mailbox. Emulation MUST print observable ping and pong events.

#### Scenario: Emulation exchanges ping and pong

- **WHEN** `projects/baremetal/dual_mcpu_emul` is built with `FSOC_EMU_EDGES=4 FSOC_EMU_FAST=1`
- **THEN** the log contains `pin ping 1` at least twice and `pin pong 1` at least twice

#### Scenario: Images differ

- **WHEN** the dual-mcpu task emits software
- **THEN** the project directory contains `cpu0.hex` and `cpu1.hex` of 64 bytes each assembled from different firmware sources
