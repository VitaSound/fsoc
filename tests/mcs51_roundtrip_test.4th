\ tests/mcs51_roundtrip_test.4th — MCS-51 A→D walk + D→A re-assemble same hex.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/8051/fasm.4th" included
mcs-wl >order
s" ../fsys/fasm/8051/disasm.4th" included

create rt-buf 64 allot
variable rt-n

: rt-save ( -- )
    fasm-pc @ rt-n !
    fasm-pc @ 0 ?do i fasm@ rt-buf i + c! loop ;

: rt-same? ( -- f )
    fasm-pc @ rt-n @ <> if false exit then
    rt-n @ 0 ?do
        i fasm@ rt-buf i + c@ <> if false unloop exit then
    loop true ;

: disasm-walk ( -- pc' )
    0 begin dup fasm-pc @ u< while fasm-dis-one repeat ;

\ A→D
s" [asm] r1 dec-rn, $07 add-a#, [endasm]" evaluate
disasm-walk fasm-pc @ expect=
rt-save

\ D→A: re-assemble the same source forms (assemblable contract).
s" [asm] r1 dec-rn, $07 add-a#, [endasm]" evaluate
rt-same? expect-true

test-finish
expect-stack-clean
cr ." mcs51_roundtrip_test ok" cr
