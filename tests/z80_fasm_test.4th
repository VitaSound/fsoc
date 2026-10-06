\ tests/z80_fasm_test.4th — Z80 comma words against documented encodings.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/z80/fasm.4th" included
z80-wl >order

s" [asm] nop, halt, di, ei, [endasm]" evaluate
0 fasm@ $00 expect=
1 fasm@ $76 expect=
2 fasm@ $F3 expect=
3 fasm@ $FB expect=

s" [asm] b c ld, a $3E ld#, [endasm]" evaluate
0 fasm@ $41 expect=
1 fasm@ $3E expect=
2 fasm@ $3E expect=

s" [asm] hl $1234 ldw, [endasm]" evaluate
0 fasm@ $21 expect=
1 fasm@ $34 expect=
2 fasm@ $12 expect=

s" [asm] nz $ABCD jpcc, [endasm]" evaluate
0 fasm@ $C2 expect=
1 fasm@ $CD expect=
2 fasm@ $AB expect=

s" [asm] ldir, [endasm]" evaluate
0 fasm@ $ED expect=
1 fasm@ $B0 expect=

s" [asm] 0 a bit, [endasm]" evaluate
0 fasm@ $CB expect=
1 fasm@ $47 expect=

s" [asm] a 5 ldix, [endasm]" evaluate
0 fasm@ $DD expect=
1 fasm@ $7E expect=
2 fasm@ $05 expect=

s" [asm] spin: spin jr, [endasm]" evaluate
0 fasm@ $18 expect=
1 fasm@ $FE expect=

s" [asm] next jrnz, next: nop, [endasm]" evaluate
0 fasm@ $20 expect=
1 fasm@ $00 expect=
2 fasm@ $00 expect=

s" [asm] af push, bc pop, sp addhl, [endasm]" evaluate
0 fasm@ $F5 expect=
1 fasm@ $C1 expect=
2 fasm@ $39 expect=

: z80-far ( -- ) 300 jr, ;
' z80-far catch 0<> expect-true

: z80-bad-r ( -- ) 8 incr, ;
' z80-bad-r catch 0<> expect-true

previous

test-finish
expect-stack-clean
cr ." z80_fasm_test ok" cr
