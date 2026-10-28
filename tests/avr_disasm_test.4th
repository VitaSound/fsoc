\ tests/avr_disasm_test.4th — AVR assemble → fasm-dis-one walk (A→D).

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included
s" ../fsys/fasm/avr/atmega8.4th" included
s" ../fsys/fasm/avr/disasm.4th" included

: disasm-walk ( -- pc' )
    0 begin
        dup fasm-pc @ u<
    while
        fasm-dis-one
    repeat ;

0 fasm-print? !
s" [asm] nop, ret, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

s" [asm] r16 1 ldi, r16 r17 add, [endasm]" evaluate
disasm-walk fasm-pc @ expect=

test-finish
expect-stack-clean
cr ." avr_disasm_test ok" cr
