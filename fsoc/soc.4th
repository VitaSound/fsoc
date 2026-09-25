\ fsoc/soc.4th — soc task: assemble firmware, copy the J1 leaf, emit top.v

variable s-dir-a
variable s-dir-u
create fsoc-design-buf 256 allot
variable fsoc-design-u
variable soc-cwd-a
create soc-cwd-buf 1024 allot
variable soc-nm-a
variable soc-nm-u

: soc-abs ( c-addr u - c-addr u )
    dup 0= IF EXIT THEN
    over c@ [char] / = IF EXIT THEN
    soc-cwd-buf soc-cwd-a @ s" /" fsoc-append
    2swap fsoc-append ;

\ First existing file wins. far is ../../ (project dir), mid is ../ (tests/),
\ near is a bare path (repo root).
: soc-pick3 ( far-a far-u mid-a mid-u near-a near-u - c-addr u )
    2>r 2>r
    2dup file-status nip 0= IF 2r> 2drop 2r> 2drop EXIT THEN
    2drop
    2r> 2dup file-status nip 0= IF 2r> 2drop EXIT THEN
    2drop
    2r> ;

: soc-join ( c-addr-name u - c-addr u )
    s-dir-a @ s-dir-u @ 2swap fsoc-append ;

variable soc-cp-a
variable soc-cp-u

: soc-cp ( c-addr-src u c-addr-dst-name u - )
    2swap soc-cp-u ! soc-cp-a !
    soc-join
    s" cp -f " soc-cp-a @ soc-cp-u @ fsoc-append
    s"  " fsoc-append
    2swap fsoc-append
    2dup system
    fsoc-str-free ;

: soc-prefixed ( c-addr-prefix u - c-addr u )
    soc-nm-a @ soc-nm-u @ fsoc-append ;

: soc-cpu@ ( c-addr-name u - c-addr u )
    soc-nm-u ! soc-nm-a !
    s" ../../cpu/j1/" soc-prefixed
    s" ../cpu/j1/" soc-prefixed
    s" cpu/j1/" soc-prefixed
    soc-pick3 ;

: soc-emu@ ( c-addr-name u - c-addr u )
    soc-nm-u ! soc-nm-a !
    s" ../../emu/" soc-prefixed
    s" ../emu/" soc-prefixed
    s" emu/" soc-prefixed
    soc-pick3 ;

: soc-rtl@ ( c-addr-name u - c-addr u )
    soc-nm-u ! soc-nm-a !
    s" ../../rtl/" soc-prefixed
    s" ../rtl/" soc-prefixed
    s" rtl/" soc-prefixed
    soc-pick3 ;

: soc-fw@ ( c-addr-name u - c-addr u )
    soc-nm-u ! soc-nm-a !
    s" ../../firmware/" soc-prefixed
    s" ../firmware/" soc-prefixed
    s" firmware/" soc-prefixed
    soc-pick3
    soc-abs ;

: soc-main@ ( - c-addr u )
    s" ../../fsoc/soc_main.cpp"
    s" ../fsoc/soc_main.cpp"
    s" fsoc/soc_main.cpp" soc-pick3 ;

: soc-top-src@ ( - c-addr u )
    fsoc-design-u @ 0= IF true abort" project design unset" THEN
    fsoc-design-buf fsoc-design-u @ soc-abs ;

: soc-gen-top ( - )
    s" FSOC_SOC_TOP="
    s-dir-a @ s-dir-u @ soc-abs fsoc-append
    s"  ${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen build " fsoc-append
    soc-top-src@ fsoc-append
    s"  2>fhdlgen.log" fsoc-append
    2dup system
    fsoc-str-free
    $? 0= 0= IF
        s" cat fhdlgen.log >&2" system
        true abort" fhdlgen build soc top failed"
    THEN ;

: soc-swap@ ( c-addr-name u - c-addr u )
    soc-nm-u ! soc-nm-a !
    s" ../../cpu/j1/swapforth/" soc-prefixed
    s" ../cpu/j1/swapforth/" soc-prefixed
    s" cpu/j1/swapforth/" soc-prefixed
    soc-pick3
    soc-abs ;

: soc-sh ( c-addr u c-addr-msg u - )
    2swap
    2dup system
    fsoc-str-free
    $? 0= IF 2drop EXIT THEN
    type cr
    true abort" command failed" ;

: soc-cross ( - )
    ."     cross: swapforth/j1a/nuc.fs" cr
    s" cd "
    s" j1a" soc-swap@ fsoc-append
    s"  && mkdir -p build && gforth cross.fs basewords.fs nuc.fs >build/cross.out" fsoc-append
    s"  || { cat build/cross.out >&2; exit 1; }" fsoc-append
    s\"  && awk '{ for (i = 1; i <= NF; i++) if ($i == \"tdp\") printf \"    SwapForth nucleus: dictionary at $%s bytes of 8192, code pointer %s\\n\", $(i+1), $(i+3) }' build/cross.out" fsoc-append
    s" swapforth cross failed" soc-sh
    s" cp -f "
    s" j1a/build/nuc.hex" soc-swap@ fsoc-append
    s"  " fsoc-append
    s" /firmware.hex" soc-join fsoc-append
    s" copy nucleus hex failed" soc-sh ;

variable soc-lamp?

: soc-lamp-on ( - ) 1 soc-lamp? ! ;

: soc-feed-file ( c-addr u - )
    s" env -u FSOC_EMU_UART_IN -u FSOC_EMU_UART_BYTES -u FSOC_EMU_CON FSOC_EMU_FAST=1 FSOC_EMU_SNAPSHOT=1 FSOC_EMU_FEED="
    2swap fsoc-append
    s"  sh sim.sh >feed.log" fsoc-append
    s" swapforth feed failed" soc-sh ;

: soc-fw-size ( - )
    s\" awk 'function hex(s, i,c,n) { n=0; for (i=1;i<=length(s);i++) { c=index(\"0123456789abcdef\", tolower(substr(s,i,1))); if (c==0) return -1; n=n*16+c-1 } return n } NR==FNR { for (i=1;i<=NF;i++) if ($i==\"dpaddr\") dp=hex($(i+1)); next } FNR==dp/2+1 && dp>0 { printf \"    firmware.hex: %d bytes of 8192\\n\", hex($1); ok=1; exit } END { if (!ok) exit 1 }' " 
    s" j1a/build/cross.out" soc-swap@ fsoc-append
    s"  firmware.hex" fsoc-append
    s" firmware size failed" soc-sh ;

: soc-feed ( - )
    ."     firmware: swapforth/j1a/swapforth.fs" cr
    s" j1a/swapforth.fs" soc-swap@ soc-feed-file
    soc-lamp? @ IF
        ."     firmware: firmware/lamp.fs" cr
        s" lamp.fs" soc-fw@ soc-feed-file
    THEN
    soc-fw-size ;

variable soc-slash

: soc-basename ( c-addr u -- c-addr u )
    -1 soc-slash !
    dup 0 ?do
        over i + c@ [char] / = if i soc-slash ! then
    loop
    soc-slash @ 0< if exit then
    soc-slash @ 1+ /string ;

: soc-note ( c-addr u -- )
    cr ." fsoc: "
    soc-cwd-buf soc-cwd-a @ soc-basename type
    ."  - " type cr ;

create leaf-buf 128 allot
variable leaf-u
variable leaf-fd

\ Name comes from an include line of the design this project named.
: soc-copy-named ( c-addr u -- )
    dup 127 > IF true abort" include name too long" THEN
    dup leaf-u !
    leaf-buf swap cmove
    leaf-buf leaf-u @ soc-cpu@
    2dup file-status nip 0= 0= IF
        2drop
        leaf-buf leaf-u @ soc-rtl@
    THEN
    2>r
    s" /" leaf-buf leaf-u @ fsoc-append
    2r> 2swap
    soc-cp ;

: soc-copy-leaves ( -- )
    s\" awk -F\\\" '/include/{print $2}' "
    s" /top.v" soc-join fsoc-append
    s"  > " fsoc-append
    s" /includes.lst" soc-join fsoc-append
    2dup system
    fsoc-str-free
    $? 0= 0= IF true abort" include list failed" THEN
    s" /includes.lst" soc-join r/o open-file throw leaf-fd !
    begin
        leaf-buf 127 leaf-fd @ read-line throw
    while
        ?dup IF leaf-buf swap soc-copy-named THEN
    repeat
    drop
    leaf-fd @ close-file throw ;

: soc-emit-emulation ( c-addr-dir u - )
    s-dir-u ! s-dir-a !
    soc-cwd-buf 1024 get-dir nip soc-cwd-a !
    s" Start build" soc-note
    s" Hardware" soc-note
    s" mkdir -p " s-dir-a @ s-dir-u @ fsoc-append
    2dup system
    fsoc-str-free
    s" con.h" soc-emu@ s" /con.h" soc-cp
    s" con.cc" soc-emu@ s" /con.cc" soc-cp
    soc-main@ s" /soc_main.cpp" soc-cp
    cores-minimal-soc
    s" /csr.4th" soc-join csr-export-4th
    s" /csr.json" soc-join csr-export-json
    soc-gen-top
    soc-copy-leaves
    s" Hardware complete" soc-note
    s" /sim.sh" soc-join emu-write-sim-sh
    s" Software" soc-note
    soc-cross
    soc-feed
    s" Software complete" soc-note
    0 soc-lamp? ! ;
