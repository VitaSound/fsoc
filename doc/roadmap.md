# fsoc roadmap

## Done (0.1.0)

- Platform DSL and three boards
- Quartus + Icarus/Verilator emit
- Blinky vertical slice
- CSR + uart/gpio/timer/ctrl
- J1 wrapper, prompt sim, fterm, FOOTSWITCH-SCAN host

## Next

- Vendor full J1a RTL from swapforth and boot swapforth under Icarus
- UART-compatible `emit`/`key` on J1; USB-UART on EP4CE10
- Host CSR bridge (litex_server analogue)
- Import more boards from litex-boards
- yosys/nextpnr (iCE40/ECP5/Gowin) and Vivado
- Expression tree + Forth FHDL sim (with fhdlgen)
- Own Forth CPU described in fhdlgen DSL
- Audio cores from hdl-modules behind CSR (Forth synthesizer)
