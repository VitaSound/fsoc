\ tests/avr_roundtrip_test.4th — AVR A→D walk + D→A re-assemble same hex.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included
s" ../fsys/fasm/avr/atmega8.4th" included
s" ../fsys/fasm/avr/disasm.4th" included

create rt-buf 64 cells allot
variable rt-n

: rt-save ( -- )
    fasm-pc @ rt-n !
    fasm-pc @ 0 ?do i fasm@ rt-buf i cells + ! loop ;

: rt-same? ( -- f )
    fasm-pc @ rt-n @ <> if false exit then
    rt-n @ 0 ?do
        i fasm@ rt-buf i cells + @ <> if false unloop exit then
    loop true ;

: disasm-walk ( -- pc' )
    0 begin dup fasm-pc @ u< while fasm-dis-one repeat ;

0 fasm-print? !

\ Fixed-opcode assemblable forms (disasm prints nop, / ret,).
s" [asm] nop, ret, [endasm]" evaluate
disasm-walk fasm-pc @ expect=
rt-save
s" [asm] nop, ret, [endasm]" evaluate
rt-same? expect-true

\ Encoded-operand forms: same source → same hex (D→A contract on source).
s" [asm] r16 1 ldi, r16 r17 add, [endasm]" evaluate
disasm-walk fasm-pc @ expect=
rt-save
s" [asm] r16 1 ldi, r16 r17 add, [endasm]" evaluate
rt-same? expect-true

test-finish
expect-stack-clean
cr ." avr_roundtrip_test ok" cr
