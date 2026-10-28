\ tests/golden-src/z80/programs.4th — golden programs for Z80 fasm.

s" ../../test_common.4th" included
s" ../../fixture.4th" included
s" ../../../fsys/fasm/z80/fasm.4th" included
z80-wl >order

: emit-image ( name-a name-u -- )
    cr ." IMAGE " 2dup type ."  "
    base @ >r hex
    fasm-pc @ 0 ?do
        i fasm@ 0 <# # # #> type space
    loop
    r> base !
    cr ;

0 fasm-print? !
s" [asm] nop, ret, [endasm]" evaluate
s" basic" emit-image

s" [asm] a 1 ld#, b add, [endasm]" evaluate
s" add" emit-image

s" [asm] loop: b decr, loop jrnz, [endasm]" evaluate
s" branch" emit-image

bye
