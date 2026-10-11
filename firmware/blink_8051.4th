\ firmware/blink_8051.4th — toggle P1.0. No Forth kernel.
\ Entry at 0 (soft R8051 / Proteus reset). Short delay for Verilator.

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
r2 $02 mov-rn#,
d1:
r1 $04 mov-rn#,
d0:
r1 dec-rn,
d0 jnz,
r2 dec-rn,
d1 jnz,
blink sjmp,
[endasm]
previous
