\ tests/fasm_test.4th — host assembler for j1a and j1b

s" test_common.4th" included

: asm$ ( c-addr u -- out-a out-u )
    ['] evaluate >string-execute ;

: expect-s ( c-addr1 u1 c-addr2 u2 -- )
    2over 2over compare 0= expect-true
    2drop 2drop ;

s" ../fsys/fasm/j1a/fasm.4th" included

s\" [asm]\nmain:\n1 imm,\n2 imm,\nadd call,\nspin:\nspin jmp,\nadd:\n+,\nexit,\n[endasm]" asm$
s\" 8001\n8002\n4004\n0003\n6203\n608c\n" expect-s

s" [asm] 1 imm, +, dup, exit, [endasm]" asm$ 2drop
0 fasm@ $8001 expect=
1 fasm@ $6203 expect=
2 fasm@ $6011 expect=
3 fasm@ $608c expect=

s" [asm] noop, +, -, xor, and, or, invert, =, <, u<, swap, dup, drop, over, nip, >r, r>, r@, 2/, 2*, depth, exit, hack, [endasm]" asm$ 2drop
0 fasm@ $6000 expect=
1 fasm@ $6203 expect=
2 fasm@ $6c03 expect=
3 fasm@ $6503 expect=
4 fasm@ $6303 expect=
5 fasm@ $6403 expect=
6 fasm@ $6600 expect=
7 fasm@ $6703 expect=
8 fasm@ $6803 expect=
9 fasm@ $6f03 expect=
10 fasm@ $6110 expect=
11 fasm@ $6011 expect=
12 fasm@ $6103 expect=
13 fasm@ $6111 expect=
14 fasm@ $6003 expect=
15 fasm@ $6127 expect=
16 fasm@ $6b1d expect=
17 fasm@ $6b11 expect=
18 fasm@ $6900 expect=
19 fasm@ $6a00 expect=
20 fasm@ $6e11 expect=
21 fasm@ $608c expect=
22 fasm@ $6040 expect=

s" [asm] 2dupand, 2dup<, 2dup=, 2dupor, 2dup+, 2dupu<, 2dupxor, dup>r, overand, over>, over=, overor, over+, overu>, overxor, rdrop, tuck!, !, io@, iord, io!, [endasm]" asm$ 2drop
0 fasm@ $6311 expect=
1 fasm@ $6811 expect=
2 fasm@ $6711 expect=
3 fasm@ $6411 expect=
4 fasm@ $6211 expect=
5 fasm@ $6f11 expect=
6 fasm@ $6511 expect=
7 fasm@ $6024 expect=
8 fasm@ $6300 expect=
9 fasm@ $6800 expect=
10 fasm@ $6700 expect=
11 fasm@ $6400 expect=
12 fasm@ $6200 expect=
13 fasm@ $6f00 expect=
14 fasm@ $6500 expect=
15 fasm@ $600c expect=
16 fasm@ $6033 expect=
17 fasm@ $6033 expect=
18 fasm@ $6d00 expect=
19 fasm@ $6050 expect=
20 fasm@ $6043 expect=

s" [asm] 9 imm, 3 jmp, 4 call, 5 0branch, [endasm]" asm$ 2drop
0 fasm@ $8009 expect=
1 fasm@ $0003 expect=
2 fasm@ $4004 expect=
3 fasm@ $2005 expect=

s\" [asm]\n\\ comment\n1 imm,\n[endasm]" asm$ 2drop
0 fasm@ $8001 expect=
fasm-pc @ 1 expect=

: fasm-bad ( -- )
    s" [asm] missing call, [endasm]" evaluate ;
' fasm-bad catch 0<> expect-true

s" ../fsys/fasm/j1b/fasm.4th" included

s\" [asm]\nmain:\n1 imm,\n2 imm,\nadd call,\nspin:\nspin jmp,\nadd:\n+,\nexit,\n[endasm]" asm$
s\" 80028001\n00034004\n608c6203\n" expect-s

s" [asm] @, [endasm]" asm$ 2drop
0 fasm@ $6c00 expect=

s" [asm] rshift, lshift, depths, 2duprshift, dup@, @, [endasm]" asm$ 2drop
0 fasm@ $6903 expect=
1 fasm@ $6a03 expect=
2 fasm@ $6e11 expect=
3 fasm@ $6911 expect=
4 fasm@ $6c11 expect=
5 fasm@ $6c00 expect=

cr ." fasm_test ok" cr
