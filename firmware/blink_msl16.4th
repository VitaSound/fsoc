\ firmware/blink_msl16.4th — toggle the LED port. No Forth kernel.
\ Word 0 is the level. The delay counter lives at $7E0, under the I/O window.

include ../fsys/fasm/msl16/fasm.4th
msl16-wl >order

[asm]
0 dcw,
nop,
spin:
drop,
0 lit,
@,
1 lit,
xor,
dup,
0 lit,
swap,
!,
drop,
dup,
2032 lit,
swap,
!,
drop,
drop,
255 lit,
2016 lit,
swap,
!,
drop,
dly:
2016 lit,
@,
1 lit,
-,
dup,
2016 lit,
swap,
!,
drop,
dup,
0=,
spin 1- lit,
and,
goto,
dly 1- lit,
goto,
[endasm]
previous
