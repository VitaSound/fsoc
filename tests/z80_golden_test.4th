\ tests/z80_golden_test.4th — hex-diff Z80 fasm against tests/golden/z80-golden.4th.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/z80/fasm.4th" included
z80-wl >order
s" golden/z80-golden.4th" included

create hexbuf 512 chars allot
variable hexlen

: fasm-hex! ( -- )
    0 hexlen !
    base @ >r hex
    fasm-pc @ 0 ?do
        i fasm@ 0 <# # # #> hexbuf hexlen @ + swap cmove
        2 hexlen +!
    loop
    r> base ! ;

: golden-expect ( src-a src-u golden-a golden-u -- )
    { ga gu }
    0 fasm-print? !
    s" [asm] " pad place
    pad +place
    s"  [endasm]" pad +place
    pad count evaluate
    fasm-hex!
    hexbuf hexlen @ ga gu compare 0= expect-true ;

s" nop, ret," golden:basic golden-expect
s" a 1 ld#, b add," golden:add golden-expect
s" loop: b decr, loop jrnz," golden:branch golden-expect

test-finish
expect-stack-clean
cr ." z80_golden_test ok" cr
