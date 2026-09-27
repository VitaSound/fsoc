\ fsoc/tasks/soc.4th — soc task: CSR, top.v, J1 leaves, SwapForth image.
\ Paths come from FSOC_HOME; the output directory is the project.
\ Option lamp=1 appends firmware/lamp.fs to the flattened feed.

: soc-design ( project -- c-addr u )
    project.design@ dup 0= IF true abort" project design unset" THEN ;

variable soc-board-top?
0 soc-board-top? !
variable soc-view?
0 soc-view? !

variable soc-clk
variable soc-cpu

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

: soc-kit-param ( extra-a extra-u name-a name-u file-a file-u -- c-addr u )
    2>r 2>r
    s"  --param " fsoc-cat+
    2r> fsoc-cat+
    s" =" fsoc-cat+
    2r> fsoc-cat+ ;

: soc-kit-params ( extra-a extra-u -- c-addr u )
    soc-cpu @ cpu.kit @ { kit }
    kit kit.hdr$ @ fsoc-fetch dup IF
        s" HDR" 2swap soc-kit-param
    ELSE 2drop THEN
    kit kit.stack$ @ fsoc-fetch s" STACK" 2swap soc-kit-param
    kit kit.core$ @ fsoc-fetch s" CORE" 2swap soc-kit-param
    kit kit.wrap$ @ fsoc-fetch s" WRAP" 2swap soc-kit-param ;

: soc-gen-top ( project -- )
    >r
    s"  --out " r@ project.dir@ fjson.str-concat
    s"  --param CLK_HZ=" fsoc-cat+
    soc-board-top? @ soc-view? @ or IF soc-clk-hz ELSE soc-feed-hz THEN
    fjson.u>str fsoc-cat++
    s"  --param BAUD=115200" fsoc-cat+
    soc-board-top? @ IF
        s"  --param BOARD=1" fsoc-cat+
        soc-serial? 0= IF s"  --param NO_UART=1" fsoc-cat+ THEN
        soc-led-low? IF s"  --param LED_LOW=1" fsoc-cat+ THEN
        s"  --param TIMER_DIV=" fsoc-cat+
        soc-clk-hz 1000 / fjson.u>str fsoc-cat++
    THEN
    soc-kit-params
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
    s" swapforth/" 2swap fjson.str-concat
    fsoc-path+ ;

\ <id>/<tail> under swapforth/. The id is the cpu profile.
: soc-port ( -- c-addr u )
    soc-cpu @ cpu.id$ @ fsoc-fetch ;

: soc-swap-rel { tail-a tail-u -- abs-a abs-u }
    soc-port
    s" /" fjson.str-concat
    tail-a tail-u fsoc-cat+
    2dup 2>r
    soc-swap
    2r> fjson.str-free ;

: soc-cross-dir ( -- abs-a abs-u )
    soc-port soc-swap ;

\ Leaf named by an include line: the kit directory, then cpu/j1/, then rtl/.
: soc-try-leaf ( name-a name-u rel-a rel-u -- abs-a abs-u flag )
    2swap fjson.str-concat fsoc-path+
    2dup file-exists? ;

: soc-leaf-src ( name-a name-u -- abs-a abs-u )
    soc-cpu @ cpu.kit @ ?dup IF
        kit.id$ @ fsoc-fetch
        s" cpu/j1/" 2swap fjson.str-concat
        s" /" fsoc-cat+
        2>r 2dup 2r@ soc-try-leaf IF
            2r> fjson.str-free 2nip EXIT
        THEN
        fjson.str-free
        2r> fjson.str-free
    THEN
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

: soc-ram-bytes ( -- n )
    soc-cpu @ cpu.kit @
    dup kit.ram @ swap kit.width @ 8 / * ;

: soc-cross ( project -- )
    >r
    s" nuc.fs" soc-swap-rel 2dup ."     " type cr fjson.str-free
    s" cd "
    soc-cross-dir fsoc-+cat
    s"  && mkdir -p build && gforth cross.fs basewords.fs nuc.fs >build/cross.out" fsoc-cat+
    s"  || { cat build/cross.out >&2; exit 1; }" fsoc-cat+
    s\"  && awk '{ for (i = 1; i <= NF; i++) if ($i == \"tdp\") printf \"    SwapForth nucleus: dictionary at $%s bytes of " fsoc-cat+
    soc-ram-bytes fjson.u>str fsoc-cat++
    s\" , code pointer %s\\n\", $(i+1), $(i+3) }' build/cross.out" fsoc-cat+
    s" swapforth cross failed" sh-run+
    s" build/nuc.hex" soc-swap-rel 2dup
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

\ One line for every image tool: firmware.hex: <used> bytes of <ram>.
\ addr is the byte address of the cell that holds the used-byte count.
: soc-image-line { addr -- }
    soc-cpu @ cpu.kit @ { kit }
    kit kit.width @ 8 / { bytes }
    kit kit.ram @ bytes * { cap }
    s" awk -v dp="
    addr fjson.u>str fsoc-+cat
    s"  -v bytes=" fsoc-cat+
    bytes fjson.u>str fsoc-+cat
    s"  -v cap=" fsoc-cat+
    cap fjson.u>str fsoc-+cat
    s\"  'function hex(s, i,c,n) { n=0; for (i=1;i<=length(s);i++) { c=index(\"0123456789abcdef\", tolower(substr(s,i,1))); if (c==0) return -1; n=n*16+c-1 } return n } FNR==int(dp/bytes)+1 && dp>0 { printf \"    firmware.hex: %d bytes of %d\\n\", hex($1), cap; ok=1; exit } END { if (!ok) exit 1 }' firmware.hex" fsoc-cat+
    s" firmware size failed" sh-run+ ;

\ SwapForth prints dpaddr in hex after dumpall sets base.
: soc-dp-addr ( -- n )
    s\" awk 'function hex(s, i,c,n) { n=0; for (i=1;i<=length(s);i++) { c=index(\"0123456789abcdef\", tolower(substr(s,i,1))); if (c==0) return -1; n=n*16+c-1 } return n } { for (i=1;i<=NF;i++) if ($i==\"dpaddr\") print hex($(i+1)) }' "
    s" build/cross.out" soc-swap-rel fsoc-+cat
    s"  > dp.addr" fsoc-cat+
    s" firmware size failed" sh-run+
    s" dp.addr" fsoc-read-line1
    2dup s>number? if
        drop >r
        fjson.str-free
        s" dp.addr" sh-rm
        r>
    else
        2drop
        fjson.str-free
        s" dp.addr" sh-rm
        true abort" firmware size failed"
    then ;

: soc-fw-size ( -- )
    soc-dp-addr soc-image-line ;

: soc-feed ( project -- )
    >r
    s" FSOC_EMU_COMPILE_ONLY=1 sh sim.sh" s" verilator compile failed" sh-run
    s" swapforth.fs" soc-swap-rel
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

\ Empty sys: is swapforth. The task calls that tool's one step.
: soc-sys-id ( project -- c-addr u )
    project.sys@ dup IF EXIT THEN
    2drop s" swapforth" ;

\ The manifest id is swapforth. The log uses the same name as the nucleus line.
: soc-tool-label ( c-addr u -- c-addr u )
    2dup s" swapforth" compare 0= if 2drop s" SwapForth" then ;

: soc-sys-step ( project -- )
    dup >r
    soc-sys-id { id-a id-u }
    id-a id-u sys-find ?dup IF
        ."     image tool: " id-a id-u soc-tool-label type cr
        r> swap sys.step @ execute
    ELSE
        rdrop
        id-a id-u stderr write-file throw
        s\" \n" stderr write-file throw
        stderr flush-file throw
        true abort" unknown sys"
    THEN ;

: soc-swapforth ( project -- )
    dup soc-cross
    soc-feed ;

\ fsys image: assemble the kernel, then let that kernel compile fsys/common.
\ SwapForth's cross is not used. lamp.fs is not appended.
: soc-kernel ( -- )
    s" fsys/kernel/" soc-port fjson.str-concat
    s" /kernel.4th" fjson.str-concat
    fsoc-path included ;

: soc-fsys-feed ( -- )
    s" FSOC_EMU_COMPILE_ONLY=1 sh sim.sh" s" verilator compile failed" sh-run
    ."     fsys/common/common.4th" cr
    ."     fsys/common/core.4th" cr
    s" cat "
    s" fsys/common/common.4th" fsoc-path fsoc-+cat
    s"  " fsoc-cat+
    s" fsys/common/core.4th" fsoc-path fsoc-+cat
    s"  > feed.fs" fsoc-cat+
    s" fsys feed cat failed" sh-run+
    s" env -u FSOC_EMU_UART_IN -u FSOC_EMU_UART_BYTES -u FSOC_EMU_CON -u FSOC_EMU_CYCLES FSOC_EMU_FAST=1 FSOC_EMU_FEED=feed.fs ./obj_dir/Vtop_feed >feed.log"
    s" fsys common feed failed" sh-run ;

\ j1a keeps kernel-save. j1b's saver is jb-save so both files can
\ sit in one tree without a second definition of the same name.
: soc-kernel-save ( c-addr u -- )
    s" j1b" soc-port compare 0= if
        s" jb-save"
    else
        s" kernel-save"
    then
    find-name name>interpret execute ;

: soc-here-addr ( -- n )
    s" j1b" soc-port compare 0= if
        s" jb-here"
    else
        s" kernel-here"
    then
    find-name name>interpret execute ;

: soc-fsys ( project -- )
    >r
    soc-kernel
    s" firmware.hex" r> project.file
    2dup
    soc-kernel-save
    fjson.str-free
    soc-fsys-feed
    soc-here-addr soc-image-line ;

\ CG=I builds the image with the tool named by sys:.
\ A 32-bit profile without its wrapper stops here and writes no hex.
: soc-cg-i ( project cpu -- )
    dup cpu-image? 0= IF
        nip
        s" needs a WIDTH 32 wrapper with mem_din" cpu-stop
    THEN
    soc-cpu !
    >r
    s" Start build" fsoc-note
    s" Hardware" fsoc-note
    s" fsoc/tasks/soc_main.cpp" harness:
    s" fsoc/tasks/soc_feed.cpp" r@ project-copy-in
    s" csr.fs" r@ project.file 2dup iomap-export-fs fjson.str-free
    s" iomap.vh" r@ project.file 2dup iomap-export-vh fjson.str-free
    s" csr.json" r@ project.file 2dup iomap-export-json fjson.str-free
    r@ target-of target.sim @ soc-view? !
    0 soc-board-top? !
    r@ soc-gen-top
    r@ soc-copy-leaves
    r@ soc-map-board
    s" Hardware complete" fsoc-note
    s" Software" fsoc-note
    r@ emu-emit
    r@ soc-sys-step
    r@ project.board@ nip soc-view? @ 0= and IF
        1 soc-board-top? !
        r@ soc-gen-top
        s" rm -f sim.sh" s" keep sim.sh off board" sh-run
    THEN
    s" Software complete" fsoc-note
    rdrop ;

\ Empty cpu: on this task is j1a. Any other id must be a registered profile.
: soc-cpu-id ( project -- c-addr u )
    project.cpu@ dup IF EXIT THEN
    2drop s" j1a" ;

: soc-cpu-of ( project -- cpu )
    soc-cpu-id 2dup cpu-find ?dup IF nip nip EXIT THEN
    s" unknown cpu " 2swap fjson.str-concat
    2dup stderr write-file throw
    s\" \n" stderr write-file throw
    stderr flush-file throw
    fjson.str-free
    true abort" unknown cpu" ;

: soc-emit ( project -- )
    dup soc-sys-id 2dup sys-find 0= IF
        stderr write-file throw
        s\" \n" stderr write-file throw
        stderr flush-file throw
        true abort" unknown sys"
    ELSE
        2drop
    THEN
    dup soc-cpu-of cg-run ;

s" I" ' soc-cg-i cg-register
s" soc" ' soc-emit task-register
s" swapforth" ' soc-swapforth sys-register
s" fsys" ' soc-fsys sys-register
