\ tests/8051_fasm_test.4th — MCS-51 comma words and relative labels.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/8051/fasm.4th" included
mcs-wl >order

s" [asm] nop, ret, [endasm]" evaluate
0 fasm@ $00 expect=
1 fasm@ $22 expect=

s" [asm] P1 $01 mov-di#, [endasm]" evaluate
0 fasm@ $75 expect=
1 fasm@ $90 expect=
2 fasm@ $01 expect=

s" [asm] spin: spin sjmp, [endasm]" evaluate
0 fasm@ $80 expect=
1 fasm@ $FE expect=

s" [asm] P1 $00 mov-di#, blink: P1 $01 xrl-di#, r1 $02 mov-rn#, dly: r1 dec-rn, dly jnz, blink sjmp, [endasm]" evaluate
0 fasm@ $75 expect=
1 fasm@ $90 expect=
2 fasm@ $00 expect=
3 fasm@ $63 expect=
4 fasm@ $90 expect=
5 fasm@ $01 expect=
6 fasm@ $79 expect=
7 fasm@ $02 expect=
8 fasm@ $19 expect=
9 fasm@ $70 expect=
10 fasm@ $FD expect=
11 fasm@ $80 expect=
12 fasm@ $F6 expect=

previous

test-finish
expect-stack-clean
cr ." 8051_fasm_test ok" cr
