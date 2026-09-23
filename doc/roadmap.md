# fsoc roadmap

## Done (0.1.0)

- Platform DSL and three boards
- Quartus + Icarus/Verilator emit
- Blinky vertical slice
- CSR + uart/gpio/timer/ctrl
- J1 wrapper, prompt sim, fterm, FOOTSWITCH-SCAN host

## Blinky architecture (current)

- Task: leaf [`rtl/blinky.v`](../rtl/blinky.v) (`clk` / `led`, `LED_BIT` default 25) plus [`designs/blinky_top.4th`](../designs/blinky_top.4th)
- Build `emulation`: [`targets/emulation.4th`](../targets/emulation.4th) uses `LED_BIT=25` and Verilator in realtime until Ctrl+C. [`emu/con.h`](../emu/con.h) prints `t=<ns> pin led <value>` only on change (`con_uart` is the same channel for a decoded serial byte). `fsoc blinky` loads the task here
- Build per board: [`targets/quartus.4th`](../targets/quartus.4th) `<board>` writes `build/blinky/<board>/` (`.qsf` maps `clk50` to `clk` and `user_led` to `led`). Boards: `vitasound_ep4ce10`, `rz_easyfpga`

## Path 1 — later (not a blinky blocker)

Full module bodies on Forth (fhdlgen expr-AST, structural `always`, no string RHS). Blinky logic stays a `.v` file; only `top` is generated.

## Next

- Vendor full J1a RTL from swapforth and boot swapforth under Icarus
- UART-compatible `emit`/`key` on J1; USB-UART on EP4CE10
- Host CSR bridge (litex_server analogue)
- Import more boards from litex-boards
- yosys/nextpnr (iCE40/ECP5/Gowin) and Vivado
- Expression tree + Forth FHDL sim (with fhdlgen) — path 1 for cores that should be Forth-native
- Own Forth CPU described in fhdlgen DSL
- Audio cores from hdl-modules behind CSR (Forth synthesizer)
