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
end-structure

begin-structure conn%
    field: conn.name$
    field: conn.pins$
end-structure

begin-structure plat%
    field: plat.name$
    field: plat.device$
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
    ulist-new r@ plat.ios !
    ulist-new r@ plat.conns !
    ulist-new r@ plat.reqs !
    r@ current-platform !
    r> drop ;

: plat-device ( c-addr u - )
    plat@ plat.device$ @ fsoc-free
    fsoc-store plat@ plat.device$ ! ;

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
    ulist-new current-io @ io.subs ! ;

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
    swap io.name$ @ fsoc-fetch find-io-a @ find-io-u @ fsoc-streq
    and ;

: io-find ( c-addr u index - io|0 )
    find-io-i ! find-io-u ! find-io-a !
    0 find-io-r !
    plat@ plat.ios @ ulist-head @
    begin dup while
        dup >r unode-addr @
        dup io-match? IF find-io-r ! r> drop 0
        ELSE drop r> unode-next @ THEN
    repeat drop
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

: request-all ( c-addr u - )
    find-io-u ! find-io-a !
    plat@ plat.ios @ ulist-head @
    begin dup while
        dup >r unode-addr @
        dup io.name$ @ fsoc-fetch find-io-a @ find-io-u @ fsoc-streq IF
            dup io.name$ @ fsoc-fetch rot io.index @ request
        ELSE drop THEN
        r> unode-next @
    repeat drop ;

: plat.ios-len ( - n )
    plat@ plat.ios @ ulist-len ;

: plat.reqs-len ( - n )
    plat@ plat.reqs @ ulist-len ;

: plat.name@ ( - c-addr u )
    plat@ plat.name$ @ fsoc-fetch ;

: plat.device@ ( - c-addr u )
    plat@ plat.device$ @ fsoc-fetch ;
