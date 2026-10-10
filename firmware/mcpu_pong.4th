\ firmware/mcpu_pong.4th — MCPU core B: wait for 1 (ping), write 2 (pong), wait clear.

include ../fsys/fasm/mcpu/fasm.4th
0 fasm-print? !
mcpu-wl >order

[asm]
wait1:
ff nor,
62 add,
m1 add,
wait1 jcc,
ff nor,
two add,
62 sta,
wait0:
ff nor,
62 add,
zero nor,
one add,
wait0 jcc,
ff nor,
zero add,
wait1 jcc,
ff: 255 dcb,
one: 1 dcb,
two: 2 dcb,
zero: 0 dcb,
m1: 255 dcb,
[endasm]
previous
