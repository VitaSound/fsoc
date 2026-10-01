\ firmware/blink_bcpu.4th — toggle the LED port. No Forth kernel.
\ 0x4000 does not fit in a 12-bit literal: 1<<12 is shifted twice.
\ Port 0 reads switches, so the level lives in a RAM cell.

include ../fsys/fasm/bcpu/fasm.4th
bcpu-wl >order

[asm]
$FFF lit,
32 stc,
1 lit,
32 lsh,
33 stc,
3 lit,
34 stc,
33 ldc,
34 lsh,
35 stc,
1 lit,
36 stc,
0 lit,
37 stc,
spin:
37 ldc,
36 xor,
37 stc,
35 sti,
spin jmp,
[endasm]
previous
