\ firmware/blink_j1abs.4th — toggle the LED port. No Forth kernel.
\ The image port is j1a, so the assembler is fsys/fasm/j1a.
\ Two nested countdowns. One pass is about a tenth of a second at 50 MHz.

include ../fsys/fasm/j1a/fasm.4th
0 fasm-print? !
hex
[asm]
on:
1 imm,
400 imm,
io!,
drop,
wait call,
0 imm,
400 imm,
io!,
drop,
wait call,
on jmp,

wait:
200 imm,
outer:
80 imm,
inner:
1 imm,
-,
dup,
inner0 0branch,
inner jmp,
inner0:
drop,
1 imm,
-,
dup,
outer0 0branch,
outer jmp,
outer0:
drop,
exit,
[endasm]
decimal
