\ tests/msl16_fasm_test.4th — MSL16 slot packing.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/msl16/fasm.4th" included
msl16-wl >order

s" [asm] nop, and, xor, +, [endasm]" evaluate
0 fasm@ $0123 expect=
fasm-pc @ 1 expect=

s" [asm] dup, [endasm]" evaluate
0 fasm@ $0800 expect=

s" [asm] and, dup, drop, [endasm]" evaluate
0 fasm@ $1890 expect=

s" [asm] 4 lit, -1 lit, [endasm]" evaluate
0 fasm@ $5004 expect=
1 fasm@ $5FFF expect=

s" [asm] and, 1 lit, [endasm]" evaluate
0 fasm@ $1000 expect=
1 fasm@ $5001 expect=

s" [asm] hop: hop call, [endasm]" evaluate
0 fasm@ $8000 expect=

s" [asm] nop, hop: hop call, [endasm]" evaluate
0 fasm@ $0000 expect=
1 fasm@ $8001 expect=

s" [asm] there call, there: nop, [endasm]" evaluate
0 fasm@ $8001 expect=
1 fasm@ $0000 expect=

s" [asm] 0=, 2/, -, >r, [endasm]" evaluate
0 fasm@ $467C expect=

s" [asm] r>, [endasm]" evaluate
0 fasm@ $0B00 expect=

s" [asm] goto, @, !, swap, [endasm]" evaluate
0 fasm@ $0ADE expect=
1 fasm@ $0F00 expect=

s" [asm] $ABCD dcw, [endasm]" evaluate
0 fasm@ $ABCD expect=

s" [asm] nop, align, and, [endasm]" evaluate
0 fasm@ $0000 expect=
1 fasm@ $1000 expect=
fasm-pc @ 2 expect=

s" [asm] 256 call, [endasm]" evaluate
0 fasm@ $8100 expect=

: msl16-far ( -- ) s" [asm] 32768 call, [endasm]" evaluate ;
' msl16-far catch 0<> expect-true

: msl16-wide ( -- ) s" [asm] 2048 lit, [endasm]" evaluate ;
' msl16-wide catch 0<> expect-true

: msl16-narrow ( -- ) s" [asm] -2049 lit, [endasm]" evaluate ;
' msl16-narrow catch 0<> expect-true

previous

test-finish
expect-stack-clean
cr ." msl16_fasm_test ok" cr
