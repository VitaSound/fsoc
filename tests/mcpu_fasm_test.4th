\ tests/mcpu_fasm_test.4th — experimental micro-core encodings.
\ https://github.com/cpldcpu/MCPU

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/mcpu/fasm.4th" included
mcpu-wl >order

s" [asm] 1 nor, 2 add, 3 sta, 4 jcc, 255 dcb, [endasm]" evaluate
0 fasm@ $01 expect=
1 fasm@ $42 expect=
2 fasm@ $83 expect=
3 fasm@ $C4 expect=
4 fasm@ $FF expect=
fasm-pc @ 5 expect=

s" [asm] 63 nor, [endasm]" evaluate
0 fasm@ $3F expect=

s" [asm] spin: spin jcc, [endasm]" evaluate
0 fasm@ $C0 expect=

: mcpu-wide ( -- ) 64 nor, ;
' mcpu-wide catch 0<> expect-true
previous

test-finish
expect-stack-clean
cr ." mcpu_fasm_test ok" cr
