\ fsoc/platform.4th — LiteX-like platform IR and DSL

begin-structure sub%
    field: sub.name$
    field: sub.pins$
end-structure

begin-structure io%
    field: io.name$
    field: io.index
    field: io.pins$
    field: io.iostd$
    field: io.misc$
    field: io.subs
    field: io.clock-hz
    field: io.low
end-structure

begin-structure conn%
    field: conn.name$
    field: conn.pins$
end-structure

begin-structure plat%
    field: plat.name$
    field: plat.device$
    field: plat.family$
    field: plat.package$
    field: plat.speed$
    field: plat.density$
    field: plat.ios
    field: plat.conns
    field: plat.reqs
end-structure

begin-structure req%
    field: req.name$
    field: req.index
    field: req.io
end-structure

variable current-platform
variable current-io

: plat@ ( - plat )
    current-platform @ dup 0= IF abort" no current platform" THEN ;

: platform-new ( c-addr u - )
    plat% allocate throw >r
    fsoc-store r@ plat.name$ !
    0 r@ plat.device$ !
    0 r@ plat.family$ !
    0 r@ plat.package$ !
    0 r@ plat.speed$ !
    0 r@ plat.density$ !
    ulist-new r@ plat.ios !
    ulist-new r@ plat.conns !
    ulist-new r@ plat.reqs !
    r@ current-platform !
    r> drop ;

: plat-device ( c-addr u - )
    plat@ plat.device$ @ fsoc-free
    fsoc-store plat@ plat.device$ ! ;

: plat-family ( c-addr u - )
    plat@ plat.family$ @ fsoc-free
    fsoc-store plat@ plat.family$ ! ;

: plat-package ( c-addr u - )
    plat@ plat.package$ @ fsoc-free
    fsoc-store plat@ plat.package$ ! ;

: plat-speed ( c-addr u - )
    plat@ plat.speed$ @ fsoc-free
    fsoc-store plat@ plat.speed$ ! ;

: plat-density ( c-addr u - )
    plat@ plat.density$ @ fsoc-free
    fsoc-store plat@ plat.density$ ! ;

variable io-nm-a
variable io-nm-u
variable io-idx

: io-begin ( c-addr u index - )
    io-idx ! io-nm-u ! io-nm-a !
    io% allocate throw current-io !
    io-idx @ current-io @ io.index !
    io-nm-a @ io-nm-u @ fsoc-store current-io @ io.name$ !
    0 current-io @ io.pins$ !
    0 current-io @ io.iostd$ !
    0 current-io @ io.misc$ !
    0 current-io @ io.clock-hz !
    0 current-io @ io.low !
    ulist-new current-io @ io.subs ! ;

: plat-clock-hz ( n -- )
    current-io @ 0= IF abort" plat-clock-hz outside io" THEN
    current-io @ io.clock-hz ! ;

: io.clock-hz@ ( io -- n )
    io.clock-hz @ ;

\ Onboard LED that lights when the pin is low.
: active-low ( -- )
    current-io @ 0= IF abort" active-low outside io" THEN
    1 current-io @ io.low ! ;

: io.low@ ( io -- flag )
    io.low @ ;

: pins ( c-addr u - )
    current-io @ 0= IF abort" pins outside io" THEN
    current-io @ io.pins$ @ fsoc-free
    fsoc-store current-io @ io.pins$ ! ;

: iostd ( c-addr u - )
    current-io @ 0= IF abort" iostd outside io" THEN
    current-io @ io.iostd$ @ fsoc-free
    fsoc-store current-io @ io.iostd$ ! ;

: misc ( c-addr u - )
    current-io @ 0= IF abort" misc outside io" THEN
    current-io @ io.misc$ @ fsoc-free
    fsoc-store current-io @ io.misc$ ! ;

variable sub-nm-a
variable sub-nm-u
variable sub-pn-a
variable sub-pn-u

: subsignal ( c-addr-name u c-addr-pins u - )
    current-io @ 0= IF abort" subsignal outside io" THEN
    sub-pn-u ! sub-pn-a ! sub-nm-u ! sub-nm-a !
    sub% allocate throw >r
    sub-pn-a @ sub-pn-u @ fsoc-store r@ sub.pins$ !
    sub-nm-a @ sub-nm-u @ fsoc-store r@ sub.name$ !
    r@ current-io @ io.subs @ ulist-add
    r> drop ;

: io-end ( - )
    current-io @ 0= IF abort" io-end without io" THEN
    current-io @ plat@ plat.ios @ ulist-add
    0 current-io ! ;

: connector ( c-addr-name u c-addr-pins u - )
    conn% allocate throw >r
    fsoc-store r@ conn.pins$ !
    fsoc-store r@ conn.name$ !
    r@ plat@ plat.conns @ ulist-add
    r> drop ;

variable find-io-a
variable find-io-u
variable find-io-i
variable find-io-r

: io-match? ( io - flag )
    dup io.index @ find-io-i @ =
    swap io.name$ @ fsoc-fetch find-io-a @ find-io-u @ compare 0=
    and ;

: io-find-one ( io - )
    dup io-match? IF find-io-r ! ELSE drop THEN ;

: io-find ( c-addr u index - io|0 )
    find-io-i ! find-io-u ! find-io-a !
    0 find-io-r !
    ['] io-find-one plat@ plat.ios @ ulist-each
    find-io-r @ ;

: request ( c-addr u index - )
    2 pick 2 pick 2 pick io-find
    dup 0= IF abort" request: unknown resource" THEN
    req% allocate throw >r
    r@ req.io !
    r@ req.index !
    fsoc-store r@ req.name$ !
    r@ plat@ plat.reqs @ ulist-add
    r> drop ;

: request-one ( io - )
    dup io.name$ @ fsoc-fetch find-io-a @ find-io-u @ compare 0= IF
        dup io.name$ @ fsoc-fetch rot io.index @ request
    ELSE drop THEN ;

\ Every index of a resource name. The ios list is not changed by request.
: request-all ( c-addr u - )
    find-io-u ! find-io-a !
    ['] request-one plat@ plat.ios @ ulist-each ;

: plat.ios-len ( - n )
    plat@ plat.ios @ ulist-len ;

: plat.reqs-len ( - n )
    plat@ plat.reqs @ ulist-len ;

: plat.name@ ( - c-addr u )
    plat@ plat.name$ @ fsoc-fetch ;

: plat.device@ ( - c-addr u )
    plat@ plat.device$ @ fsoc-fetch ;

: plat.family@ ( - c-addr u )
    plat@ plat.family$ @ fsoc-fetch ;

: plat.package@ ( - c-addr u )
    plat@ plat.package$ @ fsoc-fetch ;

: plat.speed@ ( - c-addr u )
    plat@ plat.speed$ @ fsoc-fetch ;

: plat.density@ ( - c-addr u )
    plat@ plat.density$ @ fsoc-fetch ;

variable plat-clock-n
variable plat-clock-io

: plat-clock-see ( io - )
    dup io.clock-hz@ IF
        plat-clock-n @ 1+ plat-clock-n !
        plat-clock-io !
    ELSE drop THEN ;

\ The one io whose clock-hz is set. Zero or several abort.
: plat-clock ( - io )
    0 plat-clock-n !
    0 plat-clock-io !
    ['] plat-clock-see plat@ plat.ios @ ulist-each
    plat-clock-n @ 1 <> IF true abort" board clock count" THEN
    plat-clock-io @ ;

\ Include boards/<name>.4th from FSOC_HOME. A board file leaves nothing
\ on the stack; the depth check catches a broken board.
: board-load ( c-addr u - )
    s" boards/" 2swap fjson.str-concat
    s" .4th" fsoc-cat+
    fsoc-path
    depth >r
    2dup included
    depth r> <> IF true abort" board leaves stack" THEN
    fjson.str-free
    plat@ plat.family$ @ 0= IF true abort" board has no family" THEN ;
