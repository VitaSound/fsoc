\ tests/golden-src/mcs51/programs.4th — golden test programs (MCS-51).
\ Loadable driver: assembles each image and emits a tagged hex dump to
\ stdout, which tools/gen_golden.py parses into tests/golden/mcs51.json.
\ External assembler (sdas8051) can produce an independent reference offline.

s" ../../test_common.4th" included
s" ../../fixture.4th" included
s" ../../../fsys/fasm/8051/fasm.4th" included
mcs-wl >order

\ ( name-a name-u -- )  emit "IMAGE <name> " then the hex bytes.
: emit-image ( name-a name-u -- )
    ." IMAGE " 2dup type ."  "
    base @ >r hex
    fasm-pc @ 0 ?do
        i fasm@ 0 <# # # #> type space
    loop
    r> base !
    cr ;

s" [asm] 2 add-a-rn, $07 add-a#, [endasm]" evaluate
s" add" emit-image

s" [asm] $20 mov-a-di, $30 mov-di-a, $40 $50 mov-di-di, $1234 mov-dptr#, [endasm]" evaluate
s" mov" emit-image

s" [asm] loop: r1 dec-rn, loop sjmp, [endasm]" evaluate
s" branch" emit-image

s" [asm] $90 clr-bit, $91 setb-bit, $92 cpl-bit, [endasm]" evaluate
s" bit" emit-image

s" [asm] $1234 lcall, $5678 ljmp, [endasm]" evaluate
s" call" emit-image

bye
