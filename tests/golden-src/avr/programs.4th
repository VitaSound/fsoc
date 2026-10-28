\ tests/golden-src/avr/programs.4th — golden programs for AVR fasm.

s" ../../test_common.4th" included
s" ../../fixture.4th" included
s" ../../../fsys/fasm/avr/fasm.4th" included
s" ../../../fsys/fasm/avr/atmega8.4th" included

: emit-image ( name-a name-u -- )
    cr ." IMAGE " 2dup type ."  "
    base @ >r hex
    fasm-pc @ 0 ?do
        i fasm@ 0 <# # # # # #> type space
    loop
    r> base !
    cr ;

0 fasm-print? !
s" [asm] nop, ret, [endasm]" evaluate
s" basic" emit-image

s" [asm] r16 1 ldi, r17 2 ldi, r16 r17 add, [endasm]" evaluate
s" add" emit-image

s" [asm] loop: r16 dec, loop brne, [endasm]" evaluate
s" branch" emit-image

bye
