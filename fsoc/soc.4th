\ fsoc/soc.4th — soc task: assemble firmware, copy the J1 leaf, emit top.v

variable s-dir-a
variable s-dir-u
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

: soc-asm-include ( - )
    s" ../firmware/hex2readmem.4th" included
    s" ../firmware/j1asm.4th" included
    s" ../firmware/ok.4th" included ;

soc-asm-include

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

: soc-main@ ( - c-addr u )
    s" ../../fsoc/soc_main.cpp"
    s" ../fsoc/soc_main.cpp"
    s" fsoc/soc_main.cpp" soc-pick3 ;

: soc-top-src@ ( - c-addr u )
    s" ../../designs/soc_top.4th"
    s" ../designs/soc_top.4th"
    s" designs/soc_top.4th" soc-pick3
    soc-abs ;

: soc-gen-top ( - )
    s" FSOC_SOC_TOP="
    s-dir-a @ s-dir-u @ s" /top.v" fsoc-append
    soc-abs fsoc-append
    s"  ${FHDLGEN_HOME:-$HOME/fhdlgen}/bin/fhdlgen build " fsoc-append
    soc-top-src@ fsoc-append
    s"  >fhdlgen.log 2>&1" fsoc-append
    2dup system
    fsoc-str-free
    $? 0= 0= IF
        s" cat fhdlgen.log >&2" system
        true abort" fhdlgen build soc top failed"
    THEN
    cr ." Verilog: top.v" cr ;

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
    s" cd "
    s" j1a" soc-swap@ fsoc-append
    s"  && mkdir -p build && gforth cross.fs basewords.fs nuc.fs >build/cross.out" fsoc-append
    s"  || { cat build/cross.out >&2; exit 1; }" fsoc-append
    s\"  && awk '{ for (i = 1; i <= NF; i++) if ($i == \"tdp\") printf \"SwapForth nucleus: dictionary at $%s bytes of 8192, code pointer %s\\n\", $(i+1), $(i+3) }' build/cross.out" fsoc-append
    s" swapforth cross failed" soc-sh
    s" cp -f "
    s" j1a/build/nuc.hex" soc-swap@ fsoc-append
    s"  " fsoc-append
    s" /firmware.hex" soc-join fsoc-append
    s" copy nucleus hex failed" soc-sh ;

: soc-feed ( - )
    s" env -u FSOC_EMU_UART_IN -u FSOC_EMU_UART_BYTES FSOC_EMU_FAST=1 FSOC_EMU_SNAPSHOT=1 FSOC_EMU_FEED="
    s" j1a/swapforth.fs" soc-swap@ fsoc-append
    s"  sh sim.sh >feed.log" fsoc-append
    s" swapforth feed failed" soc-sh ;

: soc-emit-emulation ( c-addr-dir u - )
    s-dir-u ! s-dir-a !
    soc-cwd-buf 1024 get-dir nip soc-cwd-a !
    s" mkdir -p " s-dir-a @ s-dir-u @ fsoc-append
    2dup system
    fsoc-str-free
    s" stack2.v" soc-cpu@ s" /stack2.v" soc-cp
    s" j1.v" soc-cpu@ s" /j1.v" soc-cp
    s" uart.v" soc-cpu@ s" /uart.v" soc-cp
    s" j1_wrap.v" soc-cpu@ s" /j1_wrap.v" soc-cp
    s" con.h" soc-emu@ s" /con.h" soc-cp
    s" con.cc" soc-emu@ s" /con.cc" soc-cp
    soc-main@ s" /soc_main.cpp" soc-cp
    cores-minimal-soc
    s" /csr.4th" soc-join csr-export-4th
    s" /csr.json" soc-join csr-export-json
    soc-gen-top
    s" /sim.sh" soc-join emu-write-sim-sh
    soc-cross
    soc-feed ;
