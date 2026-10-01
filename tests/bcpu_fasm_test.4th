\ tests/bcpu_fasm_test.4th — bcpu comma words and the blink encodings.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/bcpu/fasm.4th" included
bcpu-wl >order

s" [asm] 32 or, 32 and, 32 xor, 32 add, 32 lsh, 32 rsh, 32 ldi, 32 sti, [endasm]" evaluate
0 fasm@ $0020 expect=
1 fasm@ $1020 expect=
2 fasm@ $2020 expect=
3 fasm@ $3020 expect=
4 fasm@ $4020 expect=
5 fasm@ $5020 expect=
6 fasm@ $6020 expect=
7 fasm@ $7020 expect=

s" [asm] 48 ldc, 48 stc, $FFF lit, 15 jmp, 15 jpz, sfg, spc, gfg, gpc, [endasm]" evaluate
0 fasm@ $8030 expect=
1 fasm@ $9030 expect=
2 fasm@ $AFFF expect=
3 fasm@ $C00F expect=
4 fasm@ $D00F expect=
5 fasm@ $E001 expect=
6 fasm@ $E000 expect=
7 fasm@ $F001 expect=
8 fasm@ $F000 expect=

s" [asm] spin: spin jmp, [endasm]" evaluate
0 fasm@ $C000 expect=

s" ../firmware/blink_bcpu.4th" included
0 fasm@ $AFFF expect=
1 fasm@ $9020 expect=
8 fasm@ $4022 expect=
9 fasm@ $9023 expect=
14 fasm@ $8025 expect=
18 fasm@ $C00E expect=
fasm-pc @ 19 expect=

: bcpu-wide ( -- ) 4096 lit, ;
' bcpu-wide catch 0<> expect-true
previous

test-finish
expect-stack-clean
cr ." bcpu_fasm_test ok" cr
