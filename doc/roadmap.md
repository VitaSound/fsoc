# fsoc roadmap

## Done (0.1.0)

- Platform DSL and three boards
- Quartus + Icarus/Verilator emit
- Blinky vertical slice
- CSR + uart/gpio/timer/ctrl
- J1 wrapper, prompt sim, fterm, FOOTSWITCH-SCAN host

## Blinky architecture (path 2 — current)

- Logic: pure [`rtl/blinky.v`](../rtl/blinky.v) (`clk` / `led`)
- Forth: [`designs/blinky.4th`](../designs/blinky.4th) names the file; targets copy it and emit tooling
- Board pins mapped in `.qsf` (`clk50`→`clk`, `user_led`→`led`); no Verilog body as Forth strings

## Path 1 — later (not a blinky blocker)

Full module generation on Forth (fhdlgen expr-AST, structural `always`, no string RHS). Until then path 2 is the canon: **logic = `.v` file, project/target = Forth**.

## Next

- Vendor full J1a RTL from swapforth and boot swapforth under Icarus
- UART-compatible `emit`/`key` on J1; USB-UART on EP4CE10
- Host CSR bridge (litex_server analogue)
- Import more boards from litex-boards
- yosys/nextpnr (iCE40/ECP5/Gowin) and Vivado
- Expression tree + Forth FHDL sim (with fhdlgen) — path 1 for cores that should be Forth-native
- Own Forth CPU described in fhdlgen DSL
- Audio cores from hdl-modules behind CSR (Forth synthesizer)
