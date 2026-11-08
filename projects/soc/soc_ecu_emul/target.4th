\ FPGA ECU demo — j1b control + HDL timing leaves (see plant/ + rtl/ecu_*.v)
\ Timing proof: plant/stress_*.py and tb/tb_ecu_core.v (iverilog).
\ This SoC image runs the table-only ctrl loop on UART (ecu_ctrl.fs).

s" soc" task:
s" emulation" target:
s" designs/soc_top.4th" design:
s" fsys" sys:
s" j1b" cpu:
s" ecu" s" 1" option:
