\ tests/avr_golden_test.4th — hex-diff AVR fasm against tests/golden/avr-golden.4th.

s" test_common.4th" included
s" fixture.4th" included
s" ../fsys/fasm/avr/fasm.4th" included
s" ../fsys/fasm/avr/atmega8.4th" included
s" golden/avr-golden.4th" included

create hexbuf 512 chars allot
variable hexlen

: fasm-hex! ( -- )
    0 hexlen !
    base @ >r hex
    fasm-pc @ 0 ?do
        i fasm@ 0 <# # # # # #> hexbuf hexlen @ + swap cmove
        4 hexlen +!
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
s" r16 1 ldi, r17 2 ldi, r16 r17 add," golden:add golden-expect
s" loop: r16 dec, loop brne," golden:branch golden-expect

test-finish
expect-stack-clean
cr ." avr_golden_test ok" cr
