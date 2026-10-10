\ firmware/mcpu_ping.4th — MCPU core A: write 1 (ping), wait for 2, clear, repeat.
\ Mailbox is absolute address 62 (shared in dual_pingpong.v).

include ../fsys/fasm/mcpu/fasm.4th
0 fasm-print? !
mcpu-wl >order

[asm]
start:
ff nor,
one add,
62 sta,
wait2:
ff nor,
62 add,
m2 add,
wait2 jcc,
ff nor,
zero add,
62 sta,
ff nor,
zero add,
start jcc,
ff: 255 dcb,
one: 1 dcb,
two: 2 dcb,
zero: 0 dcb,
m2: 254 dcb,
[endasm]
previous
