\ firmware/blink_8051.4th — toggle P1.0. No Forth kernel.
\ Entry at 0 (soft R8051 / Proteus reset).
\ Nested delay: short enough for Verilator pin edges, visible in Proteus.

include ../fsys/fasm/8051/fasm.4th
mcs-wl >order
0 fasm-print? !
-1 fasm-emit? !
fasm-reset
fasm-begin

[asm]
SP $60 mov-di#,
P1 $00 mov-di#,
blink:
P1 $01 xrl-di#,
r3 $08 mov-rn#,
dly2:
r2 $00 mov-rn#,
dly1:
r1 $00 mov-rn#,
dly0:
r1 dec-rn,
dly0 jnz,
r2 dec-rn,
dly1 jnz,
r3 dec-rn,
dly2 jnz,
blink sjmp,
[endasm]
previous
