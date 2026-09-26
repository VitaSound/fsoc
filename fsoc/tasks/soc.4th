\ fsoc/tasks/soc.4th — soc task: CSR, top.v, J1 leaves, SwapForth image.
\ Paths come from FSOC_HOME; the output directory is the project.
\ Option lamp=1 appends firmware/lamp.fs to the flattened feed.

: soc-design ( project -- c-addr u )
    project.design@ dup 0= IF true abort" project design unset" THEN ;

variable soc-board-top?
0 soc-board-top? !

variable soc-clk

\ Feed sim matches targets/emulation.4th (UART bit time at 50 MHz).
50000000 constant soc-feed-hz

: soc-clk-hz ( -- n )
    current-platform @ IF
        plat-clock io.clock-hz@ dup 0= IF true abort" clock resource has no frequency" THEN
    ELSE soc-feed-hz THEN ;

\ serial is optional: Colorlight shares those pins with the LED.
: soc-serial? ( -- flag )
    current-platform @ 0= IF false EXIT THEN
    s" serial" 0 io-find 0<> ;

: soc-led-low? ( -- flag )
    current-platform @ 0= IF false EXIT THEN
    s" user_led" 0 io-find dup IF io.low@ 0<> ELSE drop false THEN ;

: soc-gen-top ( project -- )
    >r
    s"  --out " r@ project.dir@ fjson.str-concat
    s"  --param CLK_HZ=" fsoc-cat+
    soc-board-top? @ IF soc-clk-hz ELSE soc-feed-hz THEN
    fjson.u>str fsoc-cat++
    s"  --param BAUD=115200" fsoc-cat+
    soc-board-top? @ IF
        s"  --param BOARD=1" fsoc-cat+
        soc-serial? 0= IF s"  --param NO_UART=1" fsoc-cat+ THEN
        soc-led-low? IF s"  --param LED_LOW=1" fsoc-cat+ THEN
        s"  --param TIMER_DIV=" fsoc-cat+
        soc-clk-hz 1000 / fjson.u>str fsoc-cat++
    THEN
    2dup r> soc-design fhdlgen-build
    fjson.str-free ;

: soc-map-board ( project -- )
    current-platform @ 0= IF drop EXIT THEN
    >r
    plat-clock soc-clk !
    soc-clk @ io.name$ @ fsoc-fetch soc-clk @ io.index @ request
    s" user_led" 0 request
    soc-serial? IF s" serial" 0 request THEN
    s" soc" quartus-project
    r@ project.top-module@ 2dup quartus-top
    s" .v" fsoc-cat+ 2dup quartus-vfile fjson.str-free
    s" clk" soc-clk-hz 1000000000 swap / fjson.u>str quartus-clock
    soc-clk @ io.name$ @ fsoc-fetch soc-clk @ io.index @ s" clk" quartus-map
    s" user_led" 0 s" led" quartus-map
    soc-serial? IF
        s" serial" 0 s" tx" s" uart_tx" quartus-map-sub
        s" serial" 0 s" rx" s" uart_rx" quartus-map-sub
    THEN
    rdrop ;

: soc-swap ( rel-a rel-u -- abs-a abs-u )
    s" cpu/j1/swapforth/" 2swap fjson.str-concat
    fsoc-path+ ;

\ Leaf named by an include line of top.v: cpu/j1/<name> or rtl/<name>.
: soc-leaf-src ( name-a name-u -- abs-a abs-u )
    2dup s" cpu/j1/" 2swap fjson.str-concat
    fsoc-path+
    2dup file-exists? IF 2nip EXIT THEN
    fjson.str-free
    s" rtl/" 2swap fjson.str-concat
    fsoc-path+ ;

create leaf-buf 128 allot
variable leaf-fd

: soc-copy-leaf ( name-a name-u project -- )
    -rot 2dup soc-leaf-src
    2dup 2>r
    2swap 4 roll project-copy-as
    2r> fjson.str-free ;

: soc-copy-leaves ( project -- )
    >r
    s" includes.lst" r@ project.file
    2dup r/o open-file throw leaf-fd !
    fjson.str-free
    begin
        leaf-buf 127 leaf-fd @ read-line throw
    while
        ?dup IF leaf-buf swap r@ soc-copy-leaf THEN
    repeat
    drop
    leaf-fd @ close-file throw
    rdrop ;

: soc-cross ( project -- )
    >r
    s" j1a/nuc.fs" soc-swap 2dup ."     " type cr fjson.str-free
    s" cd "
    s" j1a" soc-swap fsoc-+cat
    s"  && mkdir -p build && gforth cross.fs basewords.fs nuc.fs >build/cross.out" fsoc-cat+
    s"  || { cat build/cross.out >&2; exit 1; }" fsoc-cat+
    s\"  && awk '{ for (i = 1; i <= NF; i++) if ($i == \"tdp\") printf \"    SwapForth nucleus: dictionary at $%s bytes of 8192, code pointer %s\\n\", $(i+1), $(i+3) }' build/cross.out" fsoc-cat+
    s" swapforth cross failed" sh-run+
    s" j1a/build/nuc.hex" soc-swap 2dup
    s" firmware.hex" r> project-copy-as
    fjson.str-free ;

: trim-lead ( c-addr u -- c-addr u )
    begin
        dup 0= IF EXIT THEN
        over c@ dup bl = swap 9 = or
    while 1 /string
    repeat ;

: trim-trail ( c-addr u -- c-addr u )
    begin
        dup 0= IF EXIT THEN
        2dup + 1- c@ dup bl = swap 9 = or
    while 1-
    repeat ;

: starts-include? ( c-addr u -- c-addr u flag )
    dup 8 < IF 0 EXIT THEN
    2dup drop 8 s" include " compare 0= ;

create flatten-buf 256 allot
variable flatten-fd
variable flatten-n

: soc-include-src { from-a from-u name-a name-u -- path-a path-u }
    from-a from-u fsoc-dirname s" /" fjson.str-concat
    name-a name-u fsoc-cat+
    2dup file-exists? IF EXIT THEN
    fjson.str-free
    s" common/" name-a name-u fjson.str-concat
    soc-swap
    2dup file-exists? IF EXIT THEN
    true abort" swapforth include not found" ;

: soc-flatten-file ( src-a src-u -- )
    recursive
    2dup r/o open-file throw
    { src-a src-u fd }
    begin
        flatten-buf 255 fd read-line throw
    while
        flatten-n !
        flatten-buf flatten-n @ trim-lead trim-trail
        dup 0= IF 2drop
        ELSE starts-include? IF
            8 /string trim-lead trim-trail
            src-a src-u 2swap soc-include-src
            2dup soc-flatten-file
            fjson.str-free
        ELSE
            2drop
            flatten-buf flatten-n @ flatten-fd @ write-line throw
        THEN THEN
    repeat
    drop
    fd close-file throw ;

: soc-flatten ( src-a src-u dst-a dst-u -- )
    w/o create-file throw flatten-fd !
    soc-flatten-file
    flatten-fd @ close-file throw ;

: soc-fw-size ( -- )
    s\" awk 'function hex(s, i,c,n) { n=0; for (i=1;i<=length(s);i++) { c=index(\"0123456789abcdef\", tolower(substr(s,i,1))); if (c==0) return -1; n=n*16+c-1 } return n } NR==FNR { for (i=1;i<=NF;i++) if ($i==\"dpaddr\") dp=hex($(i+1)); next } FNR==dp/2+1 && dp>0 { printf \"    firmware.hex: %d bytes of 8192\\n\", hex($1); ok=1; exit } END { if (!ok) exit 1 }' "
    s" j1a/build/cross.out" soc-swap fsoc-+cat
    s"  firmware.hex" fsoc-cat+
    s" firmware size failed" sh-run+ ;

: soc-feed ( project -- )
    >r
    s" FSOC_EMU_COMPILE_ONLY=1 sh sim.sh" s" verilator compile failed" sh-run
    s" j1a/swapforth.fs" soc-swap
    2dup ."     " type cr
    s" feed.fs" r@ project.file
    2over 2over soc-flatten
    fjson.str-free fjson.str-free
    s" lamp" r@ project.opt@ s" 1" compare 0= IF
        s" firmware/lamp.fs" fsoc-path
        2dup ."     " type cr
        2dup s" lamp.fs" r@ project-copy-as
        fjson.str-free
        s" lamp.fs" r@ project.file
        s" feed-lamp.fs" r@ project.file
        2over 2over soc-flatten
        fjson.str-free fjson.str-free
        s" cat feed-lamp.fs >> feed.fs" s" lamp feed append failed" sh-run
    THEN
    s" env -u FSOC_EMU_UART_IN -u FSOC_EMU_UART_BYTES -u FSOC_EMU_CON -u FSOC_EMU_CYCLES FSOC_EMU_FAST=1 FSOC_EMU_FEED="
    s" feed.fs" r> project.file fsoc-+cat
    s"  ./obj_dir/Vtop_feed >feed.log" fsoc-cat+
    s" swapforth feed failed" sh-run+
    soc-fw-size ;

: soc-emit ( project -- )
    >r
    s" Start build" fsoc-note
    s" Hardware" fsoc-note
    s" fsoc/tasks/soc_main.cpp" harness:
    s" fsoc/tasks/soc_feed.cpp" r@ project-copy-in
    s" csr.fs" r@ project.file 2dup iomap-export-fs fjson.str-free
    s" iomap.vh" r@ project.file 2dup iomap-export-vh fjson.str-free
    s" csr.json" r@ project.file 2dup iomap-export-json fjson.str-free
    0 soc-board-top? !
    r@ soc-gen-top
    r@ soc-copy-leaves
    r@ soc-map-board
    s" Hardware complete" fsoc-note
    s" Software" fsoc-note
    r@ emu-emit
    r@ soc-cross
    r@ soc-feed
    r@ project.board@ nip IF
        1 soc-board-top? !
        r@ soc-gen-top
        s" rm -f sim.sh" s" keep sim.sh off board" sh-run
    THEN
    s" Software complete" fsoc-note
    rdrop ;

s" soc" ' soc-emit task-register
