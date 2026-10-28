\ tests/z80_disasm_test.4th — Z80 assemble → fasm-dis-one walk (A→D).

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/z80/fasm.4th" included
z80-wl >order
s" ../fsys/fasm/z80/disasm.4th" included

: disasm-walk ( -- pc' )
    0 begin
        dup fasm-pc @ u<
    while
        fasm-dis-one
    repeat ;

0 fasm-print? !
s" [asm] nop, ret, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

s" [asm] a 1 ld#, b add, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

test-finish
expect-stack-clean
cr ." z80_disasm_test ok" cr
