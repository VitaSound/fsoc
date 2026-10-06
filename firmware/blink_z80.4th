\ firmware/blink_z80.4th — toggle OUT (0), A. No Forth kernel.

include ../fsys/fasm/z80/fasm.4th
z80-wl >order

[asm]
a xor,
spin:
1 xor#,
0 outa,
b $20 ld#,
dly:
dly djnz,
spin jr,
[endasm]
previous
