# fsoc roadmap

Russian: [roadmap.md](roadmap.md).

Shipped work lives in [CHANGELOG.md](../CHANGELOG.md). This file is plans only.

## Now

- Day 1: Verilator blinky and Forth console (`3` / `ok`) — [README-eng.md](../README-eng.md).
- Quartus SoC (DE0-Nano), Colorlight / Yosys, CPU profiles — [guide-detail-eng.md](guide-detail-eng.md).
- Dual MCPU micro-cores (ping-pong) — [mcpu-pingpong.md](mcpu-pingpong.md).

## Next

1. Program the DE0-Nano and check the console: `fterm` line `1 2 + .` answers `3  ok`; in hex, `1 400 io!` lights `A15` and `0 400 io!` turns it off. OpenSpec: `openspec/changes/xilinx-soc`, section 1.
2. After that check, add a Xilinx build of the same console (`designs/soc_console.4th`, `USE_REGIO` stays 1). Same change, section 2.
3. Optional: dual **j1a** (or other soft-CPU pair) after the MCPU ping-pong pattern.

## Later

- Background task, interrupt controller, and its connection to J1 — [stm8ef-hw.md](stm8ef-hw.md)
- Host CSR bridge (litex_server analogue)
- Import more boards from litex-boards
- yosys/nextpnr for iCE40 and Gowin, and Vivado
- Expression tree + Forth FHDL sim (with fhdlgen) — path 1 for cores that should be Forth-native
- Own Forth CPU described in fhdlgen DSL
- Audio cores from hdl-modules behind CSR (Forth synthesizer)
- DIN MIDI foot controller on the SoC (`midi rx` pin is already on the board)
