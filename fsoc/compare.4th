\ fsoc/compare.4th — one task, one scenario, several cpu: profiles.
\ Image bytes come from the build's "firmware.hex: N bytes" line.
\ Cycles come from the viewer's "cycles N" line. A profile whose
\ image is not ready (no WIDTH 32 wrapper) leaves that column empty.
\ Quartus, Yosys and nextpnr are not started.

-1 constant cmp-empty

begin-structure cmp%
    field: cmp.id$
    field: cmp.mm$
    field: cmp.exc$
    field: cmp.cg$
    field: cmp.width
    field: cmp.bytes
    field: cmp.cycles
    field: cmp.tool$
    field: cmp.board$
end-structure

variable cmp-rows
variable cmp-home$
variable cmp-id-xt
variable cmp-rest-a
variable cmp-rest-u
variable cmp-fd
variable cmp-focus
variable cmp-count
variable cmp-best
variable cmp-ties
variable cmp-match?
variable cmp-seen?
2variable cmp.task
2variable cmp.scen
2variable cmp.tool
2variable cmp.board
2variable cmp.design
2variable cmp-tool0
2variable cmp-board0

0 cmp-rows !
0 cmp-home$ !

: cmp-home ( -- c-addr u )
    cmp-home$ @ fsoc-fetch ;

: cmp-tmp? ( c-addr u -- flag )
    dup 14 < IF 2drop false EXIT THEN
    drop 14 s" /tmp/fsoc-cmp-" compare 0= ;

\ Writes stay under the compare directory.
: cmp-guard ( c-addr u -- c-addr u )
    2dup cmp-tmp? 0= IF true abort" compare path leaves /tmp" THEN ;

: cmp-drop ( -- )
    cmp-home$ @ 0= IF EXIT THEN
    cmp-home cmp-tmp? 0= IF true abort" bad compare directory" THEN
    s" rm -rf " cmp-home fjson.str-concat
    s" rm failed" sh-run+
    cmp-home$ @ fsoc-free
    0 cmp-home$ ! ;

: cmp-home-new ( -- )
    cmp-home$ @ IF cmp-drop THEN
    s" /tmp/fsoc-cmp-" utime drop fjson.u>str fsoc-+cat
    2dup sh-mkdir
    2dup cmp-home$ fsoc-store!
    fjson.str-free ;

: cmp-home-ensure ( -- )
    cmp-home$ @ 0= IF cmp-home-new THEN ;

: cmp-free ( row -- )
    dup cmp.id$ @ fsoc-free
    dup cmp.mm$ @ fsoc-free
    dup cmp.exc$ @ fsoc-free
    dup cmp.cg$ @ fsoc-free
    dup cmp.tool$ @ fsoc-free
    dup cmp.board$ @ fsoc-free
    free throw ;

: cmp-init ( -- )
    cmp-rows @ 0= IF EXIT THEN
    ['] cmp-free cmp-rows @ ulist-each
    cmp-rows @ ulist-clear ;

: cmp-add ( row -- )
    cmp-rows @ 0= IF ulist-new cmp-rows ! THEN
    cmp-rows @ ulist-add ;

: cmp-new ( -- row )
    cmp% allocate throw >r
    r@ cmp% erase
    cmp-empty r@ cmp.bytes !
    cmp-empty r@ cmp.cycles !
    r> ;

: cmp-cpu ( c-addr u -- cpu )
    2dup cpu-find ?dup IF nip nip EXIT THEN
    s" unknown cpu " 2swap fjson.str-concat
    2dup stderr write-file throw
    s\" \n" stderr write-file throw
    stderr flush-file throw
    fjson.str-free
    true abort" unknown cpu" ;

: cmp-from-cpu { id-a id-u cpu tool-a tool-u board-a board-u -- row }
    cmp-new { row }
    id-a id-u row cmp.id$ fsoc-store!
    cpu cpu.mm$ @ fsoc-fetch row cmp.mm$ fsoc-store!
    cpu cpu.exc$ @ fsoc-fetch row cmp.exc$ fsoc-store!
    cpu cpu.cg$ @ fsoc-fetch row cmp.cg$ fsoc-store!
    cpu cpu.width @ row cmp.width !
    tool-a tool-u row cmp.tool$ fsoc-store!
    board-a board-u row cmp.board$ fsoc-store!
    row ;

\ Record a row that was already collected. Does not run a toolchain.
: cmp-note { id-a id-u bytes cycles tool-a tool-u board-a board-u -- }
    id-a id-u cmp-cpu { cpu }
    id-a id-u cpu tool-a tool-u board-a board-u cmp-from-cpu
    dup cmp.bytes bytes swap !
    dup cmp.cycles cycles swap !
    cmp-add ;

: cmp-num ( n -- c-addr u )
    dup 0< IF drop s" -" fjson.str-dup EXIT THEN
    fjson.u>str ;

: cmp-or-dash ( c-addr u -- c-addr u )
    dup IF fjson.str-dup EXIT THEN
    2drop s" -" fjson.str-dup ;

: cmp-sp { a1 u1 a2 u2 -- a3 u3 }
    a1 u1 s"  " fjson.str-concat { s-a s-u }
    a1 u1 fjson.str-free
    s-a s-u a2 u2 fjson.str-concat { o-a o-u }
    s-a s-u fjson.str-free
    a2 u2 fjson.str-free
    o-a o-u ;

: cmp-line ( row -- c-addr u )
    >r
    r@ cmp.id$ @ fsoc-fetch fjson.str-dup
    r@ cmp.mm$ @ fsoc-fetch fjson.str-dup cmp-sp
    r@ cmp.exc$ @ fsoc-fetch fjson.str-dup cmp-sp
    r@ cmp.cg$ @ fsoc-fetch fjson.str-dup cmp-sp
    r@ cmp.width @ cmp-num cmp-sp
    r@ cmp.bytes @ cmp-num cmp-sp
    r@ cmp.cycles @ cmp-num cmp-sp
    r@ cmp.tool$ @ fsoc-fetch fjson.str-dup cmp-sp
    r> cmp.board$ @ fsoc-fetch cmp-or-dash cmp-sp ;

: cmp-peer? { a b -- flag }
    a cmp.mm$ @ fsoc-fetch b cmp.mm$ @ fsoc-fetch compare 0= 0= IF
        false EXIT
    THEN
    a cmp.exc$ @ fsoc-fetch b cmp.exc$ @ fsoc-fetch compare 0= 0= IF
        false EXIT
    THEN
    a cmp.cg$ @ fsoc-fetch b cmp.cg$ @ fsoc-fetch compare 0= ;

: cmp-filled? ( row -- flag )
    cmp.cycles @ 0< 0= ;

: cmp-tally ( row -- )
    dup cmp-filled? 0= IF drop EXIT THEN
    dup cmp-focus @ cmp-peer? 0= IF drop EXIT THEN
    1 cmp-count +!
    cmp.cycles @
    cmp-count @ 1 = IF cmp-best ! EXIT THEN
    cmp-best @ min cmp-best ! ;

: cmp-tie ( row -- )
    dup cmp-filled? 0= IF drop EXIT THEN
    dup cmp-focus @ cmp-peer? 0= IF drop EXIT THEN
    cmp.cycles @ cmp-best @ = IF 1 cmp-ties +! THEN ;

\ Fewer cycles, and only inside one MM / EX-C / CG group.
\ A single filled row, or a tie, is not a winner.
: cmp-winner? ( row -- flag )
    dup cmp-filled? 0= IF drop false EXIT THEN
    cmp-focus !
    0 cmp-count !
    ['] cmp-tally cmp-rows @ ulist-each
    cmp-count @ 2 < IF false EXIT THEN
    0 cmp-ties !
    ['] cmp-tie cmp-rows @ ulist-each
    cmp-ties @ 1 = cmp-focus @ cmp.cycles @ cmp-best @ = and ;

: cmp-same-one ( row -- )
    cmp-seen? @ 0= IF
        dup cmp.tool$ @ fsoc-fetch cmp-tool0 2!
        cmp.board$ @ fsoc-fetch cmp-board0 2!
        true cmp-seen? !
        EXIT
    THEN
    dup cmp.tool$ @ fsoc-fetch cmp-tool0 2@ compare 0= 0= IF
        drop false cmp-match? ! EXIT
    THEN
    cmp.board$ @ fsoc-fetch cmp-board0 2@ compare 0= 0= IF
        false cmp-match? !
    THEN ;

: cmp-same? ( -- flag )
    cmp-rows @ 0= IF false EXIT THEN
    cmp-rows @ ulist-len 0= IF false EXIT THEN
    true cmp-match? !
    false cmp-seen? !
    ['] cmp-same-one cmp-rows @ ulist-each
    cmp-match? @ ;

: cmp-open ( -- )
    cmp-home s" /report.txt" fjson.str-concat
    cmp-guard
    2dup w/o create-file throw cmp-fd !
    fjson.str-free ;

: cmp-write-lit ( c-addr u -- )
    cmp-fd @ write-line throw ;

: cmp-write-free ( c-addr u -- )
    2dup cmp-write-lit fjson.str-free ;

: cmp-show-row ( row -- )
    cmp-line cmp-write-free ;

: cmp-show-win ( row -- )
    dup cmp-winner? 0= IF drop EXIT THEN
    cmp.id$ @ fsoc-fetch
    s" fewer cycles " 2swap fjson.str-concat
    cmp-write-free ;

\ Bytes are printed beside the cell width and are not ranked.
\ A smaller image at another width is not called more efficient.
: cmp-text ( -- c-addr u )
    cmp-home-ensure
    cmp-open
    s" profile mm exc cg width bytes cycles tool board" cmp-write-lit
    ['] cmp-show-row cmp-rows @ ulist-each-fifo
    cmp-same? IF
        s" core compare" cmp-write-lit
        ['] cmp-show-win cmp-rows @ ulist-each-fifo
    THEN
    cmp-fd @ close-file throw
    cmp-home s" /report.txt" fjson.str-concat
    2dup slurp-file 2swap fjson.str-free ;

: cmp-skip-bl ( c-addr u -- c-addr u )
    begin
        dup IF over c@ bl = ELSE false THEN
    while
        1 /string
    repeat ;

: cmp-each-id ( c-addr u xt -- )
    cmp-id-xt !
    begin
        cmp-skip-bl
        dup 0= IF 2drop EXIT THEN
        2dup bl scan
        cmp-rest-u ! cmp-rest-a !
        dup cmp-rest-u @ - nip
        cmp-id-xt @ execute
        cmp-rest-a @ cmp-rest-u @
        dup 0= IF 2drop EXIT THEN
        1 /string
    again ;

: cmp-digits ( c-addr u -- n true | false )
    begin dup IF over c@ bl = ELSE false THEN while 1 /string repeat
    dup 0= IF 2drop false EXIT THEN
    over c@ [char] 0 < IF 2drop false EXIT THEN
    over c@ [char] 9 > IF 2drop false EXIT THEN
    0 0 2swap >number 2drop d>s true ;

: cmp-num-after { text-a text-u key-a key-u -- n }
    text-a text-u key-a key-u search 0= IF
        key-a key-u type cr
        true abort" compare log has no field"
    THEN
    key-u /string
    cmp-digits 0= IF
        key-a key-u type cr
        true abort" compare log has no number"
    THEN ;

: cmp-reply? ( c-addr u -- flag )
    s" 3  ok" search nip nip ;

: cmp-path { dir-a dir-u name-a name-u -- c-addr u }
    dir-a dir-u s" /" fjson.str-concat { a1 u1 }
    a1 u1 name-a name-u fjson.str-concat
    a1 u1 fjson.str-free ;

: cmp-add-lit { buf-a buf-u lit-a lit-u -- c-addr u }
    buf-a buf-u lit-a lit-u fjson.str-concat
    buf-a buf-u fjson.str-free ;

: cmp-add-str { buf-a buf-u str-a str-u -- c-addr u }
    buf-a buf-u str-a str-u fjson.str-concat
    buf-a buf-u fjson.str-free ;

: cmp-decl { va vu wa wu -- c-addr u }
    s\" s\" " va vu fjson.str-concat s\" \" " fjson.str-concat { qa qu }
    qa qu wa wu fjson.str-concat { la lu }
    qa qu fjson.str-free
    la lu s\" \n" fjson.str-concat { oa ou }
    la lu fjson.str-free
    oa ou ;

: cmp-glue { a1 u1 a2 u2 -- c-addr u }
    a1 u1 a2 u2 fjson.str-concat { oa ou }
    a1 u1 fjson.str-free
    a2 u2 fjson.str-free
    oa ou ;

: cmp-manifest { id-a id-u -- c-addr u }
    cmp.task 2@ s" task:" cmp-decl
    s" emulation" s" target:" cmp-decl cmp-glue
    cmp.design 2@ s" design:" cmp-decl cmp-glue
    id-a id-u s" cpu:" cmp-decl cmp-glue { body-a body-u }
    cmp.board 2@ dup 0= IF 2drop body-a body-u EXIT THEN
    s" board:" cmp-decl
    body-a body-u 2swap cmp-glue ;

: cmp-child ( id-a id-u -- c-addr u )
    cmp-home s" /" fjson.str-concat { a1 u1 }
    a1 u1 2swap fjson.str-concat
    a1 u1 fjson.str-free ;

: cmp-append { text-a text-u path-a path-u -- }
    path-a path-u cmp-guard 2drop
    path-a path-u file-exists? 0= IF
        path-a path-u s" " fsoc-write-file
    THEN
    path-a path-u r/w open-file throw { fd }
    fd file-size throw fd reposition-file throw
    text-a text-u fd write-line throw
    fd close-file throw
    path-a path-u fjson.str-free ;

: cmp-run ( c-addr u -- )
    2dup cmp-home s" /ran.log" fjson.str-concat cmp-append
    s" compare run failed" sh-run ;

: cmp-sh-cmd { dir-a dir-u scen-a scen-u -- c-addr u }
    s" cd " fjson.str-dup dir-a dir-u cmp-add-str
    s"  && env -u FSOC_EMU_UART_BYTES -u FSOC_EMU_CYCLES -u FSOC_EMU_TRACE -u FSOC_EMU_FEED FSOC_EMU_FAST=1 FSOC_EMU_CON=term FSOC_EMU_CYCLES_OUT=1 FSOC_EMU_UART_IN='" cmp-add-lit
    scen-a scen-u cmp-add-str
    s" ' FSOC_HOME=" cmp-add-lit
    fsoc-root cmp-add-str
    s"  " cmp-add-lit
    fsoc-root cmp-add-str
    s" /bin/fsoc --build >sim.log 2>&1 || { cat sim.log >&2; exit 1; }" cmp-add-lit ;

: cmp-slurp { dir-a dir-u name-a name-u -- c-addr u }
    dir-a dir-u name-a name-u cmp-path { p-a p-u }
    p-a p-u slurp-file
    p-a p-u fjson.str-free ;

\ Emulation only, and only when this profile can build an image.
\ A synthesis toolchain is recorded and not launched. CG other than I
\ has no hex image, so its cycles cell stays empty.
: cmp-live? { cpu tool-a tool-u -- flag }
    tool-a tool-u s" emulation" compare 0= 0= IF false EXIT THEN
    cpu cpu.cg$ @ fsoc-fetch s" I" compare 0= 0= IF false EXIT THEN
    cpu cpu-image? ;

: cmp-build { id-a id-u -- bytes cycles }
    cmp.scen 2@ s" '" search nip nip IF
        true abort" scenario contains a quote"
    THEN
    id-a id-u cmp-child { dir-a dir-u }
    id-a id-u cmp-manifest { man-a man-u }
    dir-a dir-u s" target.4th" cmp-path { p-a p-u }
    p-a p-u cmp-guard 2drop
    p-a p-u man-a man-u fsoc-write-file
    p-a p-u fjson.str-free
    man-a man-u fjson.str-free
    dir-a dir-u cmp.scen 2@ cmp-sh-cmd { cmd-a cmd-u }
    cmd-a cmd-u cmp-run
    cmd-a cmd-u fjson.str-free
    dir-a dir-u s" sim.log" cmp-slurp { log-a log-u }
    log-a log-u cmp-reply? 0= IF true abort" scenario did not answer" THEN
    log-a log-u s" firmware.hex: " cmp-num-after
    log-a log-u s" cycles " cmp-num-after
    log-a log-u fjson.str-free
    dir-a dir-u fjson.str-free ;

: cmp-take { id-a id-u -- }
    id-a id-u cmp-cpu { cpu }
    id-a id-u cpu cmp.tool 2@ cmp.board 2@ cmp-from-cpu { row }
    cpu cmp.tool 2@ cmp-live? IF
        id-a id-u cmp-build
        row cmp.cycles !
        row cmp.bytes !
    THEN
    row cmp-add ;

\ One toolchain and one board on every row. design is the fhdlgen
\ path the task already uses. Profile ids are separated by spaces.
: cpu-compare { task-a task-u scen-a scen-u ids-a ids-u tool-a tool-u board-a board-u design-a design-u -- c-addr u }
    cmp-init
    cmp-home-ensure
    task-a task-u cmp.task 2!
    scen-a scen-u cmp.scen 2!
    tool-a tool-u cmp.tool 2!
    board-a board-u cmp.board 2!
    design-a design-u cmp.design 2!
    ids-a ids-u ['] cmp-take cmp-each-id
    cmp-text ;
