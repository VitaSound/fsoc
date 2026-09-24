# fsoc roadmap

## Done (0.1.0)

- Platform DSL and three boards
- Quartus + Icarus/Verilator emit
- Blinky vertical slice
- CSR + uart/gpio/timer/ctrl
- J1 wrapper, prompt sim, fterm, FOOTSWITCH-SCAN host

## Blinky architecture (current)

- Task: leaf [`rtl/blinky.v`](../rtl/blinky.v) (`clk` / `led`, `LED_BIT` default 25) plus [`designs/blinky_top.4th`](../designs/blinky_top.4th)
- Working solutions under [`projects/`](../projects/): `blinky_emul` (Verilator realtime until Ctrl+C; [`emu/con.h`](../emu/con.h) prints `t=<ns> pin led <value>` on change), `blinky_vitasound_ep4ce10`, `blinky_rz_easyfpga`
- Emit: from `projects/blinky_emul`, `fsoc --build` (sim.sh from [`targets/emulation.4th`](../targets/emulation.4th), then Verilator until Ctrl+C); from `projects/blinky_<board>`, `fsoc --build` (`.qsf` from [`targets/quartus.4th`](../targets/quartus.4th); the task maps `clk50`→`clk` and `user_led`→`led`). Task and board are in `target.4th`

## Path 1 — later (not a blinky blocker)

Full module bodies on Forth (fhdlgen expr-AST, structural `always`, no string RHS). Blinky logic stays a `.v` file; only `top` is generated.

## Next

- J1 interval counter and a 1-bit `regio` on the `io` bus, then a Forth blink started from `'BOOT` ([stm8ef-hw.md](stm8ef-hw.md)). The LED is that register bit on `top`. `FSOC_EMU_CON=term` shows the lamp text; the pin log shows `0` and `1`.
- Background task, interrupt controller, and its connection to J1 — later, same note
- USB-UART on EP4CE10 (`projects/soc_emul` already boots SwapForth J1a and answers a line)
- Host CSR bridge (litex_server analogue)
- Import more boards from litex-boards
- yosys/nextpnr (iCE40/ECP5/Gowin) and Vivado
- Expression tree + Forth FHDL sim (with fhdlgen) — path 1 for cores that should be Forth-native
- Own Forth CPU described in fhdlgen DSL
- Audio cores from hdl-modules behind CSR (Forth synthesizer)
