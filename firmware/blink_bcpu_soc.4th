\ firmware/blink_bcpu_soc.4th — LED toggles when timer port bit 0 changes.
\ Port 7 is the free-running tick. The LED level is kept in RAM:
\ a read of the LED port returns the switches.

include ../fsys/fasm/bcpu/fasm.4th
bcpu-wl >order

[asm]
$FFF lit,
64 stc,
1 lit,
64 lsh,
65 stc,
3 lit,
66 stc,
65 ldc,
66 lsh,
67 stc,
7 lit,
68 stc,
67 ldc,
68 add,
69 stc,
1 lit,
70 stc,
0 lit,
71 stc,
0 lit,
73 stc,
spin:
69 ldi,
70 and,
72 stc,
71 xor,
spin jpz,
72 ldc,
71 stc,
73 ldc,
70 xor,
73 stc,
67 sti,
spin jmp,
[endasm]
previous
