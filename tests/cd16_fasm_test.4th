\ tests/cd16_fasm_test.4th — CD16 comma words against the rev 6 encodings.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/cd16/fasm.4th" included
cd16-wl >order

s" [asm] nop, drop, ret, retd, 1 addsp, -1 addsp, -2 addsp, [endasm]" evaluate
0 fasm@ $0000 expect=
1 fasm@ $0020 expect=
2 fasm@ $0409 expect=
3 fasm@ $0009 expect=
4 fasm@ $0814 expect=
5 fasm@ $0BF4 expect=
6 fasm@ $0BE4 expect=

s" [asm] 8 8 add, 8 2 movsw, 10 10 dec, 2 div1, 2 div2, 16 rep, [endasm]" evaluate
0 fasm@ $4288 expect=
1 fasm@ $4C82 expect=
2 fasm@ $53AA expect=
3 fasm@ $7402 expect=
4 fasm@ $7502 expect=
5 fasm@ $710F expect=

s" [asm] 0 sn, 8 sn, 16 sn, 15 stsp, 0 2 cop, [endasm]" evaluate
0 fasm@ $0003 expect=
1 fasm@ $0083 expect=
2 fasm@ $000B expect=
3 fasm@ $02F5 expect=
4 fasm@ $2002 expect=

s" [asm] hop: hop br, [endasm]" evaluate
0 fasm@ $1FFF expect=

s" [asm] land br, land: [endasm]" evaluate
0 fasm@ $1000 expect=
fasm-pc @ 1 expect=

s" [asm] nop, nop, dest: dest call, [endasm]" evaluate
2 fasm@ $8001 expect=

s" [asm] 64 lit, next: next br, [endasm]" evaluate
0 fasm@ $0C06 expect=
1 fasm@ $0040 expect=
2 fasm@ $1FFF expect=
fasm-pc @ 3 expect=

s" [asm] $1234 1 movl, [endasm]" evaluate
0 fasm@ $0016 expect=
1 fasm@ $1234 expect=
fasm-pc @ 2 expect=

: cd16-odd ( -- ) 1 call, ;
' cd16-odd catch 0<> expect-true

: cd16-rep ( -- ) 0 rep, ;
' cd16-rep catch 0<> expect-true

: cd16-far ( -- ) 32 addsp, ;
' cd16-far catch 0<> expect-true

: cd16-reg ( -- ) 16 0 movss, ;
' cd16-reg catch 0<> expect-true

previous

test-finish
expect-stack-clean
cr ." cd16_fasm_test ok" cr
