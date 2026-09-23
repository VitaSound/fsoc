\ firmware/ok.4th — assembled program: wait until UART is free, send o, then k.
\ Port h# 1000 is the TX byte. Port h# 2000 bit 0 is "not busy".

variable ok-wait
variable ok-words-a
variable ok-words-u
variable ok-hex-fd
variable j1-base

: j1-ok-prog ( - )
    0 j1-org
    j1-here @ ok-wait !
    $2000 j1-lit
    j1-io@
    1 j1-lit
    j1-and
    ok-wait @ j1-0branch
    $6f j1-lit
    $1000 j1-lit
    j1-iow
    j1-drop
    j1-here @ ok-wait !
    $2000 j1-lit
    j1-io@
    1 j1-lit
    j1-and
    ok-wait @ j1-0branch
    $6b j1-lit
    $1000 j1-lit
    j1-iow
    j1-drop
    j1-here @ j1-jump ;

: j1-hex4 ( u - c-addr u )
    base @ j1-base !
    hex
    0 <# # # # # #>
    j1-base @ base ! ;

: j1-write-words ( c-addr u - )
    w/o create-file throw ok-hex-fd !
    j1-here @ 0 ?DO
        j1-mem i cells + @ j1-hex4
        ok-hex-fd @ write-line throw
    LOOP
    ok-hex-fd @ close-file throw ;

\ c-addr u is the firmware.hex path. Words land in a sibling file, then hex2readmem.
: j1-asm-ok ( c-addr u - )
    j1-ok-prog
    2dup s" .words" fsoc-append
    ok-words-u ! ok-words-a !
    ok-words-a @ ok-words-u @ j1-write-words
    ok-words-a @ ok-words-u @ 2swap hex2readmem
    s" rm -f " ok-words-a @ ok-words-u @ fsoc-append
    2dup system
    fsoc-str-free ;
