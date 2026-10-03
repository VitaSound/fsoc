\ firmware/blink_cd16.4th — toggle the LED port. No Forth kernel.

include ../fsys/fasm/cd16/fasm.4th
cd16-wl >order

[asm]
spin:
0 lit,
$8000 lit,
1 0 std,
2 addsp,
$0FFF lit,
d1:
0 0 dec,
skeq,
d1 br,
1 lit,
$8000 lit,
1 0 std,
2 addsp,
$0FFF lit,
d2:
0 0 dec,
skeq,
d2 br,
spin br,
[endasm]
previous
