# fsoc roadmap

## Done (0.1.x)

- Platform DSL and three boards
- Quartus + Verilator emit; `fsoc --build` / `--load` from the project directory, `target.4th` names task, target, board
- Blinky vertical slice: `rtl/blinky.v`, `designs/blinky_top.4th`, `projects/blinky_emul`, `blinky_vitasound_ep4ce10`, `blinky_rz_easyfpga`
- SwapForth J1a cross-compiled from source, `projects/soc_emul` answers a line with ` ok`; ncurses terminal, `FSOC_EMU_CON` views
- `regio` and interval `timer` on the J1 `io` bus (`h# 400`, `h# 800`), `'BOOT` cell, `projects/soc_blink` lamp loop
- Stubs awaiting hardware: `firmware/midi_foot.4th` (host mock of FOOTSWITCH-SCAN)
- USB-UART on EP4CE10: `projects/soc_vitasound_ep4ce10`, `fterm` device backend

## Blinky architecture (current)

- Task: leaf [`rtl/blinky.v`](../rtl/blinky.v) (`clk` / `led`, `LED_BIT` default 25) plus [`designs/blinky_top.4th`](../designs/blinky_top.4th)
- Working solutions under [`projects/`](../projects/): `blinky_emul` (Verilator realtime until Ctrl+C; [`emu/con.h`](../emu/con.h) prints `t=<ns> pin led <value>` on change), `blinky_vitasound_ep4ce10`, `blinky_rz_easyfpga`
- Emit: from `projects/blinky_emul`, `fsoc --build` (sim.sh from [`targets/emulation.4th`](../targets/emulation.4th), then Verilator until Ctrl+C); from `projects/blinky_<board>`, `fsoc --build` (`.qsf` from [`targets/quartus.4th`](../targets/quartus.4th); the task maps `clk50`→`clk` and `user_led`→`led`). Task and board are in `target.4th`

## Path 1 — later (not a blinky blocker)

Full module bodies on Forth (fhdlgen expr-AST, structural `always`, no string RHS). Blinky logic stays a `.v` file; only `top` is generated.

## Done — layer refactor 0.2.0 / SoC on board 0.3.0

Review of 0.1.1 found abstraction leaks. Six OpenSpec changes closed them:

1. `builder-hygiene` — archive finished changes, remove dead code, `fmix hook`, frules
2. `builder-core` — `project%` manifest (`task:` `target:` `board:` `design:` `option:`), task/target registry with `emit` / `run` / `load` hooks, paths from `FSOC_HOME`, fjson/fenum/ttester-ext instead of local helpers, FPGA family from the board
3. `design-out-contract` — fhdlgen `--out` / `--param` / `includes.lst`; designs stop reading the environment; one `j1_wrap` blackbox
4. `emu-lib` — `emu/` as a library (clock, uart, script); thin task `main`s; separate `feed` step writes `firmware.hex` from Verilog
5. `iomap` — one address map in Forth → `csr.fs`, `iomap.vh`, `csr.json`; `cores.4th` removed
6. `soc-board` — SoC on `vitasound_ep4ce10` over USB-UART, clock from the board, `fterm` device backend

Quartus `--load` and a live `fterm` line on USB-UART still need a machine with Quartus and the board.

## Later

- Background task, interrupt controller, and its connection to J1 — [stm8ef-hw.md](stm8ef-hw.md)
- Host CSR bridge (litex_server analogue)
- Import more boards from litex-boards
- yosys/nextpnr (iCE40/ECP5/Gowin) and Vivado
- Expression tree + Forth FHDL sim (with fhdlgen) — path 1 for cores that should be Forth-native
- Own Forth CPU described in fhdlgen DSL
- Audio cores from hdl-modules behind CSR (Forth synthesizer)
- DIN MIDI foot controller on the SoC (`midi rx` pin is already on the board)
