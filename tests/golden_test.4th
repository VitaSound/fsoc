\ tests/golden_test.4th — hex-diff fsoc fasm output against committed golden.
\ Pure Forth: no external toolchain. The golden images live in
\ tests/golden/mcs51-golden.4th (regenerated offline by gen_golden.py).

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/8051/fasm.4th" included
mcs-wl >order
s" golden/mcs51-golden.4th" included

create hexbuf 512 chars allot
variable hexlen

\ Convert fasm-buf[0..fasm-pc) to a hex string in hexbuf.
: fasm-hex! ( -- )
    0 hexlen !
    base @ >r hex
    fasm-pc @ 0 ?do
        i fasm@ 0 <# # # #> hexbuf hexlen @ + swap cmove
        2 hexlen +!
    loop
    r> base ! ;

\ Assemble src, then hex-diff fasm-buf against the golden hex string.
: golden-expect ( src-a src-u golden-a golden-u -- )
    { ga gu }
    s" [asm] " pad place
    pad +place
    s"  [endasm]" pad +place
    pad count evaluate
    fasm-hex!
    hexbuf hexlen @ ga gu compare 0= expect-true ;

s" 2 add-a-rn, $07 add-a#," golden:add golden-expect
s" $20 mov-a-di, $30 mov-di-a, $40 $50 mov-di-di, $1234 mov-dptr#," golden:mov golden-expect
s" loop: r1 dec-rn, loop sjmp," golden:branch golden-expect
s" $90 clr-bit, $91 setb-bit, $92 cpl-bit," golden:bit golden-expect
s" $1234 lcall, $5678 ljmp," golden:call golden-expect

test-finish
expect-stack-clean
cr ." golden_test ok" cr
