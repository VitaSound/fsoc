\ tests/z80_roundtrip_test.4th — Z80 A→D walk + D→A re-assemble same hex.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/z80/fasm.4th" included
z80-wl >order
s" ../fsys/fasm/z80/disasm.4th" included

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

0 fasm-print? !

s" [asm] nop, ret, [endasm]" evaluate
disasm-walk fasm-pc @ expect=
rt-save
s" [asm] nop, ret, [endasm]" evaluate
rt-same? expect-true

s" [asm] a 1 ld#, b add, [endasm]" evaluate
disasm-walk fasm-pc @ expect=
rt-save
s" [asm] a 1 ld#, b add, [endasm]" evaluate
rt-same? expect-true

test-finish
expect-stack-clean
cr ." z80_roundtrip_test ok" cr
